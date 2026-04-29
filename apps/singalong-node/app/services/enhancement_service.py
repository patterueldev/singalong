"""Service for song metadata enhancement."""

import logging
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger(__name__)


class EnhancementService:
    """Service for enhancing song metadata."""

    # Validation constraints
    MIN_TITLE_LENGTH = 1
    MAX_TITLE_LENGTH = 255
    MIN_ARTIST_LENGTH = 1
    MAX_ARTIST_LENGTH = 255
    MIN_YEAR = 1900
    MAX_YEAR = 2100
    MAX_DURATION = 86400  # 24 hours in seconds
    MIN_DURATION = 1

    # Supported languages (ISO 639-1)
    SUPPORTED_LANGUAGES = {
        "en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh", "ko",
        "ar", "hi", "bn", "pa", "te", "mr", "ta", "gu", "kn", "ml"
    }

    # Supported genres
    SUPPORTED_GENRES = {
        "Pop", "Rock", "Hip-Hop", "R&B", "Country", "Jazz", "Classical",
        "Electronic", "Folk", "Soul", "Latin", "Metal", "Punk", "Indie",
        "Alternative", "Reggae", "Blues", "Dance", "Disco", "Funk"
    }

    @staticmethod
    def validate_and_enhance(
        youtube_url: str,
        title: Optional[str] = None,
        artist: Optional[str] = None,
        year: Optional[int] = None,
        language: Optional[str] = None,
        genre: Optional[str] = None,
        duration_seconds: Optional[int] = None,
        additional_notes: Optional[str] = None,
    ) -> dict:
        """
        Validate and enhance song metadata.

        Args:
            youtube_url: YouTube URL of the song
            title: Song title (edited)
            artist: Artist name (edited)
            year: Release year
            language: Language code (ISO 639-1)
            genre: Genre classification
            duration_seconds: Duration in seconds
            additional_notes: Additional notes about the song

        Returns:
            Dictionary with validated and enhanced metadata

        Raises:
            ValueError: If validation fails
        """
        errors = []

        # Validate YouTube URL
        if not youtube_url or not isinstance(youtube_url, str):
            errors.append("youtube_url is required and must be a string")
        elif not ("youtube.com" in youtube_url or "youtu.be" in youtube_url):
            errors.append("youtube_url must be a valid YouTube URL")

        # Validate title
        if title is not None:
            title = str(title).strip()
            if len(title) < EnhancementService.MIN_TITLE_LENGTH:
                errors.append("title is required (min 1 character)")
            elif len(title) > EnhancementService.MAX_TITLE_LENGTH:
                errors.append(f"title too long (max {EnhancementService.MAX_TITLE_LENGTH} characters)")

        # Validate artist
        if artist is not None:
            artist = str(artist).strip()
            if len(artist) < EnhancementService.MIN_ARTIST_LENGTH:
                errors.append("artist is required (min 1 character)")
            elif len(artist) > EnhancementService.MAX_ARTIST_LENGTH:
                errors.append(f"artist too long (max {EnhancementService.MAX_ARTIST_LENGTH} characters)")

        # Validate year
        if year is not None:
            try:
                year = int(year)
                if year < EnhancementService.MIN_YEAR or year > EnhancementService.MAX_YEAR:
                    errors.append(
                        f"year must be between {EnhancementService.MIN_YEAR} and {EnhancementService.MAX_YEAR}"
                    )
            except (ValueError, TypeError):
                errors.append("year must be a valid integer")

        # Validate language
        if language is not None:
            language = str(language).lower().strip()
            if language not in EnhancementService.SUPPORTED_LANGUAGES:
                errors.append(
                    f"language not supported (must be one of: {', '.join(sorted(EnhancementService.SUPPORTED_LANGUAGES))})"
                )

        # Validate genre
        if genre is not None:
            genre = str(genre).strip()
            # Check if genre exists in supported list (case-insensitive)
            matching_genre = None
            for supported_genre in EnhancementService.SUPPORTED_GENRES:
                if supported_genre.lower() == genre.lower():
                    matching_genre = supported_genre
                    break
            if matching_genre:
                genre = matching_genre
            else:
                logger.warning(f"Genre '{genre}' not in standard list but accepted anyway")

        # Validate duration
        if duration_seconds is not None:
            try:
                duration_seconds = int(duration_seconds)
                if duration_seconds < EnhancementService.MIN_DURATION or duration_seconds > EnhancementService.MAX_DURATION:
                    errors.append(
                        f"duration_seconds must be between {EnhancementService.MIN_DURATION} and {EnhancementService.MAX_DURATION}"
                    )
            except (ValueError, TypeError):
                errors.append("duration_seconds must be a valid integer")

        # Validate additional notes
        if additional_notes is not None:
            additional_notes = str(additional_notes).strip()
            if len(additional_notes) > 1000:
                errors.append("additional_notes too long (max 1000 characters)")

        if errors:
            raise ValueError("; ".join(errors))

        # Return enhanced metadata
        return {
            "youtube_url": youtube_url,
            "title": title,
            "artist": artist,
            "year": year,
            "language": language,
            "genre": genre,
            "duration_seconds": duration_seconds,
            "additional_notes": additional_notes,
            "enhanced_at": datetime.now(timezone.utc).isoformat(),
            "ready_to_download": True,
        }
