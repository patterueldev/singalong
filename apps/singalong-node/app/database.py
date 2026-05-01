"""Database configuration and session management"""

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Database URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./singalong_node.db")

# Create engine with SQLite-specific options
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        echo=os.getenv("DEBUG", "False").lower() == "true",
    )
else:
    engine = create_engine(
        DATABASE_URL,
        echo=os.getenv("DEBUG", "False").lower() == "true",
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency for FastAPI to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database - create all tables"""
    # Import models to register them with Base before creating tables
    from app.models import db_models  # noqa: F401
    Base.metadata.create_all(bind=engine)


