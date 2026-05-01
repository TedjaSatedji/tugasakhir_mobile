import os
from dotenv import load_dotenv

load_dotenv()

APP_NAME = os.getenv("APP_NAME", "Questify API")
ENV = os.getenv("ENV", "development")
SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
VERIFY_TOKEN_EXPIRE_MINUTES = int(os.getenv("VERIFY_TOKEN_EXPIRE_MINUTES", "1440"))
RESET_CODE_EXPIRE_MINUTES = int(os.getenv("RESET_CODE_EXPIRE_MINUTES", "15"))

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")

SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM = os.getenv("SMTP_FROM", "")

VERIFY_URL_BASE = os.getenv("VERIFY_URL_BASE", "http://localhost:8000/auth/verify-email")

GOOGLE_AI_API_KEY = os.getenv("GOOGLE_AI_API_KEY", "")
GOOGLE_AI_MODEL = os.getenv("GOOGLE_AI_MODEL", "gemma-3-27b-it")
GOOGLE_AI_BASE_URL = os.getenv(
	"GOOGLE_AI_BASE_URL",
	"https://generativelanguage.googleapis.com/v1beta",
)
