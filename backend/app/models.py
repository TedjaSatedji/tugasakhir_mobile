from sqlalchemy import Boolean, Column, DateTime, Integer, String, Float, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    reset_code_hash = Column(String, nullable=True)
    reset_code_expires_at = Column(DateTime(timezone=True), nullable=True)
    reset_code_used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    quests = relationship("Quest", back_populates="user", cascade="all, delete-orphan")
    character = relationship("Character", back_populates="user", uselist=False, cascade="all, delete-orphan")
    daily_missions = relationship("DailyMissionState", back_populates="user", cascade="all, delete-orphan")


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(Integer, nullable=False)
    category = Column(Integer, nullable=True)
    amount = Column(Float, nullable=False)
    description = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    receipt_image_url = Column(String, nullable=True)
    detected_category = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    location_name = Column(String, nullable=True)

    user = relationship("User", back_populates="transactions")


class Quest(Base):
    __tablename__ = "quests"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    xp_reward = Column(Integer, nullable=False)
    target_amount = Column(Float, nullable=False)
    current_saved_amount = Column(Float, nullable=False, default=0.0)
    category = Column(Integer, nullable=False)
    status = Column(Integer, nullable=False)
    deadline = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False)
    progress_percentage = Column(Integer, nullable=False, default=0)

    user = relationship("User", back_populates="quests")


class Character(Base):
    __tablename__ = "characters"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    character_class = Column(Integer, nullable=False)
    level = Column(Integer, nullable=False, default=1)
    total_xp = Column(Integer, nullable=False, default=0)
    hp = Column(Integer, nullable=False, default=100)
    mp = Column(Integer, nullable=False, default=50)
    avatar_url = Column(String, nullable=True)
    stats = Column(JSON, nullable=False, default=dict)

    user = relationship("User", back_populates="character")


class DailyMissionState(Base):
    __tablename__ = "daily_missions"

    id = Column(String, primary_key=True, index=True) # missionId + "_" + date + "_" + str(userId)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    mission_id = Column(String, nullable=False)
    date = Column(String, nullable=False) # YYYY-MM-DD
    is_completed = Column(Boolean, nullable=False, default=False)
    
    user = relationship("User", back_populates="daily_missions")
