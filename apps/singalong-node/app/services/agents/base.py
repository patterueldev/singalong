"""
Base class for all enhancement agents.

Each agent executes a specific enhancement task (metadata research, lyrics lookup, etc.)
and returns results that are merged by the EnhancementOrchestrator.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any
import asyncio
import logging

logger = logging.getLogger(__name__)


class Agent(ABC):
    """
    Base class for all enhancement agents.
    
    Agents execute specific enhancement tasks (metadata research, lyrics lookup, etc.)
    and return results. The orchestrator merges results from all agents.
    
    Design:
    - Each agent is independent
    - Each agent has a timeout (default 10s)
    - Agents should return empty dict {} on error
    - Never raise exceptions (graceful degradation)
    """

    def __init__(self, timeout: int = 10, name: str = None):
        """
        Initialize agent.
        
        Args:
            timeout: Max seconds to wait for agent execution
            name: Agent name for logging
        """
        self.timeout = timeout
        self.name = name or self.__class__.__name__

    @abstractmethod
    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute agent logic.
        
        Args:
            context: Dictionary containing:
                - videoId: YouTube video ID
                - title: Song title
                - artist: Song artist (may be empty)
                - tags: List of tags
                - description: YouTube description (if available)
                - Any previous agent results
        
        Returns:
            Dictionary with agent results, or empty {} on error.
            Never raise exceptions; return {} on timeout/error.
        
        Examples:
            {
                "artist": "Rick Astley",
                "year": "1987",
                "language": "en",
                "confidence": 0.98
            }
        """
        pass

    async def call_with_timeout(self, coro) -> Dict[str, Any]:
        """
        Execute coroutine with timeout, return empty dict on timeout.
        
        Args:
            coro: Coroutine to execute
        
        Returns:
            Coroutine result or empty dict {} on timeout/error
        """
        try:
            return await asyncio.wait_for(coro, timeout=self.timeout)
        except asyncio.TimeoutError:
            logger.warning(f"Agent {self.name} timed out after {self.timeout}s")
            return {}
        except Exception as e:
            logger.error(f"Agent {self.name} error: {e}", exc_info=True)
            return {}

    async def run_safe(self, coro) -> Dict[str, Any]:
        """
        Execute agent with timeout and error handling.
        
        Wrapper that ensures:
        - Timeout is enforced
        - No exceptions escape
        - Empty dict returned on any error
        
        Args:
            coro: Coroutine to execute
        
        Returns:
            Coroutine result or empty dict {} on error
        """
        try:
            return await asyncio.wait_for(coro, timeout=self.timeout)
        except asyncio.TimeoutError:
            logger.warning(
                f"Agent {self.name} timed out after {self.timeout}s",
                extra={"agent": self.name}
            )
            return {}
        except Exception as e:
            logger.error(
                f"Agent {self.name} error: {str(e)}",
                extra={"agent": self.name, "error": str(e)},
                exc_info=True
            )
            return {}
