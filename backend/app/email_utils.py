import smtplib
from email.message import EmailMessage
from fastapi import BackgroundTasks
from .config import SMTP_FROM, SMTP_HOST, SMTP_PASSWORD, SMTP_PORT, SMTP_USER, VERIFY_URL_BASE


def _build_message(to_email: str, token: str) -> EmailMessage:
    verify_url = f"{VERIFY_URL_BASE}?token={token}"
    message = EmailMessage()
    message["Subject"] = "Verify your Questify account"
    message["From"] = SMTP_FROM
    message["To"] = to_email
    message.set_content(
        "Please verify your account by opening this link:\n" f"{verify_url}\n"
    )
    return message


def _build_reset_message(to_email: str, code: str) -> EmailMessage:
    message = EmailMessage()
    message["Subject"] = "Reset your Questify password"
    message["From"] = SMTP_FROM
    message["To"] = to_email
    message.set_content(
        "Your password reset code is:\n"
        f"{code}\n\n"
        "Enter this code in the app to continue."
    )
    return message


def send_verification_email(to_email: str, token: str, background_tasks: BackgroundTasks) -> None:
    if not SMTP_HOST or not SMTP_USER or not SMTP_PASSWORD or not SMTP_FROM:
        return

    message = _build_message(to_email, token)
    background_tasks.add_task(_send_email, message)


def send_password_reset_email(
    to_email: str, code: str, background_tasks: BackgroundTasks
) -> None:
    if not SMTP_HOST or not SMTP_USER or not SMTP_PASSWORD or not SMTP_FROM:
        return

    message = _build_reset_message(to_email, code)
    background_tasks.add_task(_send_email, message)


def _send_email(message: EmailMessage) -> None:
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as smtp:
        smtp.starttls()
        smtp.login(SMTP_USER, SMTP_PASSWORD)
        smtp.send_message(message)
