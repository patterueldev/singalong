"""Song reservation service for sessions"""

from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session as SQLSession
from sqlalchemy import func

from app.models.db_models import Reservation, ReservationStatus, Song, Session


class ReservationService:
    """Service for managing song reservations in sessions"""

    def __init__(self, db: SQLSession):
        """
        Initialize reservation service

        Args:
            db: Database session
        """
        self.db = db

    def create_reservation(
        self,
        session_id: str,
        song_id: str,
        user_id: str,
    ) -> Reservation:
        """
        Create a new song reservation

        Args:
            session_id: Session UUID
            song_id: Song UUID
            user_id: User UUID making the reservation

        Returns:
            Created Reservation object

        Raises:
            ValueError: If session/song not found, song not downloaded, or duplicate reservation
        """
        # Validate session exists
        session = self.db.query(Session).filter(Session.id == session_id).first()
        if not session:
            raise ValueError(f"Session {session_id} not found")

        # Validate song exists and is completed/downloaded
        song = self.db.query(Song).filter(Song.id == song_id).first()
        if not song:
            raise ValueError(f"Song {song_id} not found")
        if song.status != "COMPLETED":
            raise ValueError(f"Song {song_id} is not available (status: {song.status})")

        # Check for duplicate reservation in this session
        existing = self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
            Reservation.song_id == song_id,
            Reservation.status != ReservationStatus.CANCELLED,
        ).first()
        if existing:
            raise ValueError(f"Song already reserved in this session")

        # Get next position number
        max_position = self.db.query(func.max(Reservation.position)).filter(
            Reservation.session_id == session_id,
            Reservation.status != ReservationStatus.CANCELLED,
        ).scalar()
        next_position = (max_position or 0) + 1

        # Create reservation
        reservation = Reservation(
            session_id=session_id,
            song_id=song_id,
            user_id=user_id,
            position=next_position,
            status=ReservationStatus.PENDING,
            reserved_at=datetime.now(timezone.utc),
        )

        self.db.add(reservation)
        self.db.commit()
        self.db.refresh(reservation)

        return reservation

    def list_reservations(
        self,
        session_id: str,
        status: Optional[ReservationStatus] = None,
    ) -> List[Reservation]:
        """
        List all reservations for a session

        Args:
            session_id: Session UUID
            status: Optional status filter

        Returns:
            List of Reservation objects ordered by position
        """
        query = self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
        )

        if status:
            query = query.filter(Reservation.status == status)

        return query.order_by(Reservation.position).all()

    def get_reservation(self, reservation_id: str) -> Optional[Reservation]:
        """
        Get a specific reservation by ID

        Args:
            reservation_id: Reservation UUID

        Returns:
            Reservation object or None if not found
        """
        return self.db.query(Reservation).filter(
            Reservation.id == reservation_id,
        ).first()

    def update_status(
        self,
        reservation_id: str,
        new_status: ReservationStatus,
    ) -> Reservation:
        """
        Update reservation status

        Args:
            reservation_id: Reservation UUID
            new_status: New status value

        Returns:
            Updated Reservation object

        Raises:
            ValueError: If reservation not found or invalid status transition
        """
        reservation = self.get_reservation(reservation_id)
        if not reservation:
            raise ValueError(f"Reservation {reservation_id} not found")

        # Validate status transition
        valid_transitions = {
            ReservationStatus.PENDING: [ReservationStatus.PLAYING, ReservationStatus.CANCELLED],
            ReservationStatus.PLAYING: [ReservationStatus.COMPLETED, ReservationStatus.CANCELLED],
            ReservationStatus.COMPLETED: [],  # Final state
            ReservationStatus.CANCELLED: [],  # Final state
        }

        if new_status not in valid_transitions.get(reservation.status, []):
            raise ValueError(
                f"Cannot transition from {reservation.status} to {new_status}"
            )

        # Update status and timestamps
        reservation.status = new_status
        if new_status == ReservationStatus.PLAYING:
            reservation.started_at = datetime.now(timezone.utc)
        elif new_status == ReservationStatus.COMPLETED:
            reservation.completed_at = datetime.now(timezone.utc)
        elif new_status == ReservationStatus.CANCELLED:
            reservation.cancelled_at = datetime.now(timezone.utc)

        self.db.commit()
        self.db.refresh(reservation)

        return reservation

    def cancel_reservation(self, reservation_id: str) -> None:
        """
        Cancel a reservation and recalculate positions

        Args:
            reservation_id: Reservation UUID

        Raises:
            ValueError: If reservation not found
        """
        reservation = self.get_reservation(reservation_id)
        if not reservation:
            raise ValueError(f"Reservation {reservation_id} not found")

        # Mark as cancelled
        reservation.status = ReservationStatus.CANCELLED
        reservation.cancelled_at = datetime.now(timezone.utc)
        self.db.commit()

        # Recalculate positions for remaining reservations
        self._recalculate_positions(reservation.session_id)

    def _recalculate_positions(self, session_id: str) -> None:
        """
        Recalculate queue positions after cancellation

        Args:
            session_id: Session UUID
        """
        # Get all non-cancelled reservations ordered by current position
        reservations = self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
            Reservation.status != ReservationStatus.CANCELLED,
        ).order_by(Reservation.position).all()

        # Reassign positions sequentially
        for i, reservation in enumerate(reservations, start=1):
            reservation.position = i

        self.db.commit()

    def get_next_in_queue(self, session_id: str) -> Optional[Reservation]:
        """
        Get the next song in queue (first pending or playing)

        Args:
            session_id: Session UUID

        Returns:
            Next Reservation or None if none pending/playing
        """
        # Check for currently playing
        playing = self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
            Reservation.status == ReservationStatus.PLAYING,
        ).first()

        if playing:
            return playing

        # Otherwise return first pending
        return self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
            Reservation.status == ReservationStatus.PENDING,
        ).order_by(Reservation.position).first()

    def get_upcoming_queue(self, session_id: str) -> List[Reservation]:
        """
        Get all upcoming songs in queue (pending + currently playing)

        Args:
            session_id: Session UUID

        Returns:
            List of Reservation objects ordered by position
        """
        return self.db.query(Reservation).filter(
            Reservation.session_id == session_id,
            Reservation.status.in_([ReservationStatus.PENDING, ReservationStatus.PLAYING]),
        ).order_by(Reservation.position).all()
