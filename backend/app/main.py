from datetime import datetime, timedelta, timezone
from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import auth, models, schemas
from .config import APP_NAME, CORS_ORIGINS, RESET_CODE_EXPIRE_MINUTES
from .database import Base, engine, get_db
from .email_utils import send_password_reset_email, send_verification_email

Base.metadata.create_all(bind=engine)

app = FastAPI(title=APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[CORS_ORIGINS] if CORS_ORIGINS != "*" else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
