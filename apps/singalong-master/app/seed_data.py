"""Seed initial admin accounts and test data on application startup"""

import logging
from datetime import datetime, timezone
from uuid import uuid4
from sqlalchemy.orm import Session
from app.models.db_models import User, UserRole

logger = logging.getLogger(__name__)


def seed_admin_accounts(db: Session) -> None:
    """
    Seed test admin accounts if they don't exist.
    Runs on application startup.
    """
    default_admins = [
        {
            "username": "admin",
            "password_hash": "test_hash_admin123",  # Placeholder - authentication via GraphQL
            "role": UserRole.ADMIN,
        },
    ]
    
    for admin_data in default_admins:
        existing = db.query(User).filter(
            User.username == admin_data["username"]
        ).first()
        
        if not existing:
            user = User(
                id=uuid4(),
                username=admin_data["username"],
                password_hash=admin_data["password_hash"],
                role=admin_data["role"].value if hasattr(admin_data["role"], "value") else admin_data["role"],
                created_at=datetime.now(timezone.utc),
            )
            db.add(user)
            logger.info(f"Seeded admin account: {admin_data['username']}")
        else:
            logger.debug(f"Admin account already exists: {admin_data['username']}")
    
    db.commit()


def seed_database(db: Session) -> None:
    """Run all seeding operations"""
    try:
        seed_admin_accounts(db)
        logger.info("Database seeding completed successfully")
    except Exception as e:
        logger.error(f"Database seeding failed: {str(e)}", exc_info=True)
        db.rollback()
