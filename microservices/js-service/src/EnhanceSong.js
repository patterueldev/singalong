import OpenAI from "openai";
import { zodResponseFormat } from "openai/helpers/zod.mjs";
import { z } from "zod";
import jsonminify from "jsonminify";

// POST route /enhance
export function enhanceSong(app) {
  app.post('/enhance', async (req, res) => {
    const { id, songTitle, metadata } = req.body;
    const songMetadata = JSON.stringify({ id, songTitle, metadata });
    const minifiedSongMetadata = jsonminify(songMetadata);
    console.log('Received song metadata:', minifiedSongMetadata);
    const openaiKey = req.headers["openai-key"];
    const openaiModel = req.headers["openai-model"];

    const openai = new OpenAI({apiKey: openaiKey});

    const EnhancedSong = z.object({
      originalTitle: z.string(),
      artist: z.string(),
      language: z.string(),
      genres: z.array(z.string()),
      romanizedTitle: z.string(),
      englishTitle: z.string(),
      relevantTags: z.array(z.string()),
      isOffVocal: z.boolean(),
      videoHasLyrics: z.boolean(),
    });

    // prompt-engineer this
    const completion = await openai.beta.chat.completions.parse({
      model: openaiModel,
      messages: [
        { role: "system", content: "Estimated song details based on the given metadata." },
        { role: "system", content: "If the title contains words like Karaoke, Instrumental or off vocal, it's usually off vocal" },
        { role: "system", content: "If the title contains words like Karaoke or Lyrics, the video usually has lyrics" },
        { role: "user", content: minifiedSongMetadata },
      ],
      response_format: zodResponseFormat(EnhancedSong, "song"),
    });

    const enhancedSong = completion.choices[0].message.parsed;

    console.log('Enhanced song:', enhancedSong);
    res.status(200).json(enhancedSong);
  });
}