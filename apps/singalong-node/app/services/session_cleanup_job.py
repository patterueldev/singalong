"""Background job to clean up stale player assignments"""

import logging
import asyncio
from datetime import datetime, timezone, timedelta
from app.database import SessionLocal
from app.models.db_models import Session

logger = logging.getLogger(__name__)


async def session_cleanup_job(interval_seconds: int = 30, offline_timeout_seconds: int = 60):
    """
    Periodic background job to clean up stale player assignments.
    
    Scenarios handled:
    1. Player was assigned but went offline (WS died, app crashed)
    2. Node is still tracking assignment but player is unresponsive for >N seconds
    3. Admin force-disconnected player, but we want to verify it's cleared
    
    **Process**:
    - Every N seconds: Query sessions with player_id set
    - For each: Check if player_last_seen > offline_timeout
    - If yes: Clear player_id, player_name, player_platform from session
    - Log the cleanup event with reason
    
    **Configuration**:
    - interval_seconds: How often to run (default: 30s)
    - offline_timeout_seconds: Time before clearing (default: 60s)
    
    **Logging**:
    ```
    [Cleanup] cleared | session=3059 | player_id=39d1...58f | 
    offline_duration=65s | player_name=Pat's MacBook
    ```
    """
    while True:
        try:
            await asyncio.sleep(interval_seconds)
            
            db = SessionLocal()
            try:
                now = datetime.now(timezone.utc)
                timeout_threshold = now - timedelta(seconds=offline_timeout_seconds)
                
                # Find sessions with stale player assignments
                stale_sessions = db.query(Session).filter(
                    Session.player_id.isnot(None),
                    Session.status == "active"
                ).all()
                
                for session in stale_sessions:
                    # Check if player_last_seen is older than timeout
                    if session.player_last_seen and session.player_last_seen < timeout_threshold:
                        offline_duration = (now - session.player_last_seen).total_seconds()
                        
                        # Clear the assignment
                        session.player_id = None
                        session.player_name = None
                        session.player_platform = None
                        session.player_last_seen = None
                        db.commit()
                        
                        logger.warning(
                            f"[Cleanup] cleared | session={session.code} | "
                            f"player_id=...{session.player_id[-4:] if session.player_id else 'unknown'} | "
                            f"offline_duration={int(offline_duration)}s"
                        )
                    elif not session.player_last_seen:
                        # Player assigned but player_last_seen never set (edge case from old code)
                        # Don't clear yet, but log as warning
                        logger.warning(
                            f"[Cleanup] no_last_seen | session={session.code} | "
                            f"player_id={session.player_id[:8] if session.player_id and len(session.player_id) >= 8 else 'unknown'} | "
                            f"player_name={session.player_name}"
                        )
            finally:
                db.close()
        
        except asyncio.CancelledError:
            logger.info("[Cleanup] job cancelled")
            break
        except Exception as e:
            logger.exception(f"[Cleanup] job error: {str(e)}")
            # Continue on error, don't crash the background job


async def start_session_cleanup_job():
    """Start the cleanup job in background (non-blocking)"""
    logger.info(
        "[Cleanup] starting | interval=30s | offline_timeout=60s"
    )
    # Create task but don't await it—let it run in background
    asyncio.create_task(session_cleanup_job(interval_seconds=30, offline_timeout_seconds=60))
