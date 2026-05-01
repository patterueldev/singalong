"""
Song Lookup Service

Handles checking if a song already exists in Master's database
and returning appropriate responses to the Node.
"""

import logging
from typing import Optional, Dict, Tuple

from app.services.graphql_client import MasterGraphQLClient, GraphQLError

logger = logging.getLogger(__name__)


class SongLookupError(Exception):
    """Raised when song lookup fails"""
    pass


class SongLookupService:
    """Service for looking up songs in Master database"""

    def __init__(self, master_graphql_url: str):
        """
        Initialize song lookup service

        Args:
            master_graphql_url: Master GraphQL endpoint URL
        """
        self.graphql_client = MasterGraphQLClient(master_graphql_url)

    async def check_song_exists(
        self, video_id: str, title: str = ""
    ) -> Tuple[bool, Optional[Dict]]:
        """
        Check if a song exists in Master database by video ID or title

        Args:
            video_id: YouTube video ID
            title: Song title (optional fallback)

        Returns:
            Tuple of (exists: bool, song_data: Optional[Dict])
            - If found: (True, {id, title, artist, status, ...})
            - If not found: (False, None)

        Raises:
            SongLookupError: If query fails
        """
        try:
            # Try to find by video ID first (most reliable)
            query = """
            query LookupSongByVideoId($videoId: String!) {
              lookupSongByVideoId(videoId: $videoId) {
                id
                title
                artist
                duration
                videoId
                status
                year
                genre
              }
            }
            """

            response = await self.graphql_client.execute_query(
                query, variables={"videoId": video_id}
            )

            song_data = response.get("lookupSongByVideoId")
            if song_data:
                logger.info(f"Song found in Master: {song_data.get('title')}")
                return True, song_data

            # If not found by video ID and title provided, try by title as fallback
            if title:
                logger.info(
                    f"Song not found by video ID, trying by title: {title}"
                )
                query = """
                query LookupSongByTitle($title: String!) {
                  lookupSongByTitle(title: $title) {
                    id
                    title
                    artist
                    duration
                    videoId
                    status
                    year
                    genre
                  }
                }
                """

                response = await self.graphql_client.execute_query(
                    query, variables={"title": title}
                )

                song_data = response.get("lookupSongByTitle")
                if song_data:
                    logger.info(f"Song found by title: {song_data.get('title')}")
                    return True, song_data

            logger.info(f"Song not found in Master: {title or video_id}")
            return False, None

        except GraphQLError as e:
            logger.error(f"GraphQL error checking song existence: {str(e)}")
            raise SongLookupError(f"Failed to check song: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error checking song: {str(e)}")
            raise SongLookupError(f"Unexpected error: {str(e)}")
