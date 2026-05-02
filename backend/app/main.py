from datetime import datetime, timedelta, timezone
import json
import re

import httpx
import os
import shutil
from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, Query, Security, UploadFile, File
from fastapi.staticfiles import StaticFiles
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import auth, models, schemas
from .config import (
    APP_NAME,
    CORS_ORIGINS,
    GOOGLE_AI_API_KEY,
    GOOGLE_AI_BASE_URL,
    GOOGLE_AI_MODEL,
    RESET_CODE_EXPIRE_MINUTES,
)
from .database import Base, engine, get_db
from .email_utils import send_password_reset_email, send_verification_email

Base.metadata.create_all(bind=engine)

app = FastAPI(title=APP_NAME)
security = HTTPBearer()

os.makedirs("uploads/images", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db),
) -> models.User:
    token = credentials.credentials
    try:
        payload = auth.decode_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    if auth.is_verify_token(payload):
        raise HTTPException(status_code=401, detail="Invalid token type")

    email = payload.get("sub")
    if not email:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
        
    return user

app.add_middleware(
    CORSMiddleware,
    allow_origins=[CORS_ORIGINS] if CORS_ORIGINS != "*" else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _extract_json_payload(text: str) -> dict:
    """Extract a single JSON object from AI text that may contain
    markdown fences, arrays, or surrounding prose."""
    cleaned = text.strip()

    # Strip markdown code fences
    fence_match = re.search(r"```(?:json)?\s*\n?([\s\S]*?)\n?```", cleaned)
    if fence_match:
        cleaned = fence_match.group(1).strip()

    parsed = json.loads(cleaned)

    # If the AI returned an array of items, merge them into one summary
    if isinstance(parsed, list) and len(parsed) > 0:
        total_amount = sum((item.get("amount") or 0) for item in parsed)
        first = parsed[0]
        descriptions = [item.get("description", "") for item in parsed if item.get("description")]
        return {
            "amount": total_amount,
            "description": "; ".join(descriptions) if descriptions else first.get("description"),
            "date": first.get("date"),
            "category": first.get("category"),
            "type": first.get("type"),
        }

    return parsed


@app.post("/upload/image")
async def upload_image(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")
        
    file_extension = file.filename.split(".")[-1]
    import uuid
    new_filename = f"{uuid.uuid4().hex}.{file_extension}"
    file_path = f"uploads/images/{new_filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Assuming standard setup, return the relative URL
    return {"url": f"/uploads/images/{new_filename}"}

@app.post("/ai/receipt-extract", response_model=schemas.ReceiptExtractResponse)
async def extract_receipt(file: UploadFile = File(...)):
    if not GOOGLE_AI_API_KEY:
        raise HTTPException(status_code=500, detail="AI API key is not configured")

    prompt = (
        "You are extracting receipt/income information from an image. "
        "Return ONLY a single valid JSON object (NOT an array) with the TOTAL values: "
        "amount (number - the grand total of the receipt), "
        "description (string - a brief summary of the purchase), "
        "date (YYYY-MM-DD or empty string if not visible), "
        "category (one of: food, fashion, hobby, transport, health, education, entertainment, other), "
        "type (income or expense or unknown). "
        "Do NOT list individual items. Return one object with the total amount."
    )

    contents = await file.read()
    import base64
    image_base64 = base64.b64encode(contents).decode("utf-8")
    mime_type = file.content_type or "image/jpeg"

    url = f"{GOOGLE_AI_BASE_URL}/models/{GOOGLE_AI_MODEL}:generateContent"
    request_body = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": prompt},
                    {
                        "inlineData": {
                            "mimeType": mime_type,
                            "data": image_base64,
                        }
                    },
                ],
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 256,
        },
    }

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            url,
            params={"key": GOOGLE_AI_API_KEY},
            json=request_body,
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"AI request failed: {response.text}",
        )

    data = response.json()
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        print(f"[AI DEBUG] Full API response: {json.dumps(data, indent=2)[:500]}")
        raise HTTPException(status_code=502, detail="AI response was invalid")

    print(f"[AI DEBUG] Raw AI text: {text[:500]}")

    try:
        payload_json = _extract_json_payload(text)
    except Exception:
        raise HTTPException(status_code=502, detail=f"AI response was not JSON: {text[:300]}")

    return schemas.ReceiptExtractResponse(
        amount=payload_json.get("amount"),
        description=payload_json.get("description"),
        date=payload_json.get("date"),
        category=payload_json.get("category"),
        type=payload_json.get("type"),
    )


@app.post("/auth/register", response_model=schemas.MessageResponse)
def register(
    payload: schemas.RegisterRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = auth.get_password_hash(payload.password)
    user = models.User(
        email=payload.email,
        hashed_password=hashed_password,
        is_verified=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = auth.create_verification_token(payload.email)
    send_verification_email(payload.email, token, background_tasks)

    return {"message": "Registration successful. Please verify your email."}


@app.post("/auth/login", response_model=schemas.TokenResponse)
def login(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user or not auth.verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not user.is_verified:
        raise HTTPException(status_code=403, detail="Email not verified")

    access_token = auth.create_access_token(payload.email)
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "is_verified": user.is_verified,
        },
    }


@app.get("/auth/verify-email", response_model=schemas.MessageResponse)
def verify_email(
    token: str = Query(..., min_length=10),
    db: Session = Depends(get_db),
):
    try:
        payload = auth.decode_token(token)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    if not auth.is_verify_token(payload):
        raise HTTPException(status_code=400, detail="Invalid token type")

    email = payload.get("sub")
    if not email:
        raise HTTPException(status_code=400, detail="Invalid token")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.is_verified:
        return {"message": "Email already verified"}

    user.is_verified = True
    db.add(user)
    db.commit()

    return {"message": "Email verified successfully"}


@app.post("/auth/request-password-reset", response_model=schemas.MessageResponse)
def request_password_reset(
    payload: schemas.PasswordResetRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if user:
        code = auth.create_reset_code()
        user.reset_code_hash = auth.get_password_hash(code)
        user.reset_code_expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=RESET_CODE_EXPIRE_MINUTES
        )
        user.reset_code_used_at = None
        db.add(user)
        db.commit()

        send_password_reset_email(payload.email, code, background_tasks)

    return {"message": "If the email exists, a reset code was sent."}


@app.post("/auth/verify-reset-code", response_model=schemas.MessageResponse)
def verify_reset_code(payload: schemas.PasswordResetVerify, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid code or email")

    if not user.reset_code_hash or not user.reset_code_expires_at:
        raise HTTPException(status_code=400, detail="Invalid code or email")

    if user.reset_code_used_at:
        raise HTTPException(status_code=400, detail="Code already used")

    expires_at = user.reset_code_expires_at
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at and expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Code expired")

    if not auth.verify_password(payload.code, user.reset_code_hash):
        raise HTTPException(status_code=400, detail="Invalid code or email")

    return {"message": "Code verified"}


@app.post("/auth/reset-password", response_model=schemas.MessageResponse)
def reset_password(payload: schemas.PasswordResetConfirm, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid code or email")

    if not user.reset_code_hash or not user.reset_code_expires_at:
        raise HTTPException(status_code=400, detail="Invalid code or email")

    if user.reset_code_used_at:
        raise HTTPException(status_code=400, detail="Code already used")

    expires_at = user.reset_code_expires_at
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at and expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Code expired")

    if not auth.verify_password(payload.code, user.reset_code_hash):
        raise HTTPException(status_code=400, detail="Invalid code or email")

    user.hashed_password = auth.get_password_hash(payload.new_password)
    user.reset_code_used_at = datetime.now(timezone.utc)
    user.reset_code_hash = None
    user.reset_code_expires_at = None
    db.add(user)
    db.commit()

    return {"message": "Password reset successful"}


# --- Sync Endpoints ---

@app.get("/sync/transactions", response_model=list[schemas.TransactionSchema])
def get_transactions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    return current_user.transactions


@app.post("/sync/transactions", response_model=schemas.TransactionSchema)
def upsert_transaction(
    payload: schemas.TransactionSchema,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    transaction = db.query(models.Transaction).filter(
        models.Transaction.id == payload.id,
        models.Transaction.user_id == current_user.id
    ).first()

    if not transaction:
        transaction = models.Transaction(id=payload.id, user_id=current_user.id)
        db.add(transaction)

    # Update fields
    for key, value in payload.model_dump().items():
        if key != "id":
            setattr(transaction, key, value)

    db.commit()
    db.refresh(transaction)
    return transaction


@app.delete("/sync/transactions/{transaction_id}")
def delete_transaction(
    transaction_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    db.query(models.Transaction).filter(
        models.Transaction.id == transaction_id,
        models.Transaction.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Transaction deleted"}


@app.get("/sync/quests", response_model=list[schemas.QuestSchema])
def get_quests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    return current_user.quests


@app.post("/sync/quests", response_model=schemas.QuestSchema)
def upsert_quest(
    payload: schemas.QuestSchema,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    quest = db.query(models.Quest).filter(
        models.Quest.id == payload.id,
        models.Quest.user_id == current_user.id
    ).first()

    if not quest:
        quest = models.Quest(id=payload.id, user_id=current_user.id)
        db.add(quest)

    for key, value in payload.model_dump().items():
        if key != "id":
            setattr(quest, key, value)

    db.commit()
    db.refresh(quest)
    return quest


@app.delete("/sync/quests/{quest_id}")
def delete_quest(
    quest_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    db.query(models.Quest).filter(
        models.Quest.id == quest_id,
        models.Quest.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Quest deleted"}


@app.get("/sync/character", response_model=schemas.CharacterSchema | None)
def get_character(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    return current_user.character


@app.post("/sync/character", response_model=schemas.CharacterSchema)
def upsert_character(
    payload: schemas.CharacterSchema,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    character = db.query(models.Character).filter(
        models.Character.id == payload.id,
        models.Character.user_id == current_user.id
    ).first()

    if not character:
        character = models.Character(id=payload.id, user_id=current_user.id)
        db.add(character)

    for key, value in payload.model_dump().items():
        if key != "id":
            setattr(character, key, value)

    db.commit()
    db.refresh(character)
    return character


@app.get("/sync/daily_missions", response_model=list[schemas.DailyMissionStateSchema])
def get_daily_missions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    return current_user.daily_missions


@app.post("/sync/daily_missions", response_model=schemas.DailyMissionStateSchema)
def upsert_daily_mission(
    payload: schemas.DailyMissionStateSchema,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    mission = db.query(models.DailyMissionState).filter(
        models.DailyMissionState.id == payload.id,
        models.DailyMissionState.user_id == current_user.id
    ).first()

    if not mission:
        mission = models.DailyMissionState(id=payload.id, user_id=current_user.id)
        db.add(mission)

    for key, value in payload.model_dump().items():
        if key != "id":
            setattr(mission, key, value)

    db.commit()
    db.refresh(mission)
    return mission
