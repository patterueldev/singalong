import ytdl from '@distube/ytdl-core';

class IdentifiedSong {
  constructor(
    id,
    source,
    imageUrl,
    songTitle,
    songArtist,
    songLanguage,
    isOffVocal,
    videoHasLyrics,
    songLyrics,
    lengthSeconds,
    metadata
  ) {
    this.id = id;
    this.source = source;
    this.imageUrl = imageUrl;
    this.songTitle = songTitle;
    this.songArtist = songArtist;
    this.songLanguage = songLanguage;
    this.isOffVocal = isOffVocal;
    this.videoHasLyrics = videoHasLyrics;
    this.songLyrics = songLyrics;
    this.lengthSeconds = lengthSeconds;
    this.metadata = metadata;
  }

  static fromJson(json) {
    return new IdentifiedSong(
      json.id,
      json.source,
      json.imageUrl,
      json.songTitle,
      json.songArtist,
      json.songLanguage,
      json.isOffVocal,
      json.videoHasLyrics,
      json.songLyrics,
      json.lengthSeconds,
      json.metadata
    );
  }
}

// POST route /identify
export function identifySong(app) {
  app.post('/identify', async (req, res) => {
    const data = req.body;
    // Process the data here
    console.log('Received data:', data);
    try {
      let info = await ytdl.getInfo(data.url)
      let videoDetails = info.videoDetails
      let lengthSecondsRaw = videoDetails.lengthSeconds
      let lengthSeconds = parseInt(lengthSecondsRaw)
      let description = videoDetails.description

      console.log("Video Details: " + JSON.stringify(videoDetails))

      // Send a response
      const identified = new IdentifiedSong(
        info.videoDetails.videoId,
        info.videoDetails.video_url,
        info.videoDetails.thumbnails[0].url,
        info.videoDetails.media.song ?? info.videoDetails.title,
        info.videoDetails.media.artist ?? "",
        "",
        false,
        false,
        "",
        lengthSeconds,
        {
          description: description,
          keywords: videoDetails.keywords ?? [],
        }
      );

      res.status(200).json(identified);
    } catch (error) {
      console.error(error);
      res.status(500).send({
        success: false,
        message: error,
      });
    }
  });
}