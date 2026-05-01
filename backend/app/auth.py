from datetime import datetime, timedelta, timezone
import secrets
from jose import JWTError, jwt
from passlib.context import CryptContext
from .config import ALGORITHM, SECRET_KEY, ACCESS_TOKEN_EXPIRE_MINUTES, VERIFY_TOKEN_EXPIRE_MINUTES

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": subject, "exp": expire, "type": "access"}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_verification_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=VERIFY_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": subject, "exp": expire, "type": "verify"}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_reset_code(length: int = 6) -> str:
    max_value = 10 ** length
    code = secrets.randbelow(max_value)
    return str(code).zfill(length)


def decode_token(token: str) -> dict:
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])


def is_verify_token(payload: dict) -> bool:
    return payload.get("type") == "verify"


