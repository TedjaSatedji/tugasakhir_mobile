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
