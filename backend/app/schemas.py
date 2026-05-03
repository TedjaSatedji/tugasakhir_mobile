from datetime import datetime
from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetVerify(BaseModel):
    email: EmailStr
    code: str


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str
    new_password: str


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    is_verified: bool


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class MessageResponse(BaseModel):
    message: str


class ReceiptExtractRequest(BaseModel):
    image_base64: str
    mime_type: str


class ReceiptExtractResponse(BaseModel):
    amount: float | None = None
    description: str | None = None
    date: str | None = None
    category: str | None = None
    type: str | None = None


# --- Sync Schemas ---

class TransactionSchema(BaseModel):
    id: str
    type: int
    category: int | None = None
    amount: float
    description: str
    timestamp: datetime
    receipt_image_url: str | None = None
    detected_category: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    location_name: str | None = None


class QuestSchema(BaseModel):
    id: str
    title: str
    description: str
    xp_reward: int
    target_amount: float
    current_saved_amount: float
    category: int
    status: int
    deadline: datetime
    created_at: datetime
    progress_percentage: int


class CharacterSchema(BaseModel):
    id: str
    name: str
    character_class: int
    level: int
    total_xp: int
    hp: int
    mp: int
    avatar_url: str | None = None
    stats: dict
    coins: int = 0
    shop_upgrades: dict = {}
    owned_frames: list = []


class DailyMissionStateSchema(BaseModel):
    id: str
    mission_id: str
    date: str
    is_completed: bool
