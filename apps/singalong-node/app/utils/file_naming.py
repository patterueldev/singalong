"""File naming utility for normalized video filenames (shared with Master)"""

import re
import unicodedata


def generate_filename(original_title: str, video_id: str) -> str:
    """
    Generate a normalized filename from YouTube title and video ID.
    
    Conversion rules:
    - Remove all non-ASCII alphanumeric characters (kanji, special chars, diacriticals, etc.)
    - Keep spaces (converted to underscores)
    - Convert to lowercase
    - Append [video_id] at the end
    - Add .mp4 extension
    
    Examples:
    - "[Karaoke 0] Aqours - 未熟DREAMER (Mijuku DREAMER)" 
      → "karaoke_0_aqours_dreamer_mijuku_dreamer[x_6nob9_WLc].mp4"
    - "バカミテイル (BAKAMITAI) - Japanese Song"
      → "bakamitai_japanese_song[dQw4w9WgXcQ].mp4"
    - "Song/Title:With-Symbols!"
      → "songtitlewithsymbols[abc123def45].mp4"
    
    Args:
        original_title: YouTube video title
        video_id: YouTube video ID (11 characters)
    
    Returns:
        Normalized filename ready for filesystem storage, e.g.:
        "karaoke_0_aqours_dreamer[x_6nob9_WLc].mp4"
    """
    
    # Step 1: Normalize unicode to decompose accented characters and kanji
    # Decompose characters: café → ca + ◌̈ + fe
    normalized = unicodedata.normalize('NFKD', original_title)
    
    # Step 2: Keep only ASCII alphanumeric + spaces
    # Remove all non-ASCII: kanji, diacriticals, special chars
    # Keep only: a-z, A-Z, 0-9, and spaces
    cleaned = ''
    for char in normalized:
        # Check if ASCII letter (a-z, A-Z), digit (0-9), or space
        if (ord(char) < 128 and (char.isalnum() or char == ' ')):
            cleaned += char
    
    # Step 3: Normalize spaces to underscores and lowercase
    filename = cleaned.strip().lower()
    filename = re.sub(r'\s+', '_', filename)  # Multiple spaces → single underscore
    filename = re.sub(r'_+', '_', filename)   # Multiple underscores → single underscore
    filename = filename.strip('_')             # Remove leading/trailing underscores
    
    # Step 4: Append video ID and extension
    if not video_id:
        video_id = 'unknown'
    
    final_filename = f"{filename}[{video_id}].mp4"
    
    return final_filename


def extract_video_id_from_filename(filename: str) -> str:
    """
    Extract video ID from a generated filename.
    
    Args:
        filename: Filename in format "name[video_id].mp4"
    
    Returns:
        Video ID extracted from brackets
    """
    match = re.search(r'\[([^\]]+)\]\.mp4$', filename)
    if match:
        return match.group(1)
    return None
