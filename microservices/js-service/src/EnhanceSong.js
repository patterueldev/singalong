import OpenAI from "openai";
import { zodResponseFormat } from "openai/helpers/zod.mjs";
import { z } from "zod";

// POST route /enhance
export function enhanceSong(app) {
  app.post('/enhance', async (req, res) => {
    const songMetadata = req.body;
    console.log('Received song metadata:', songMetadata);
    const openaiKey = req.headers["openai-key"];

    const openai = new OpenAI({apiKey: openaiKey});

    const EnhancedSong = z.object({
      title: z.string(),
      artist: z.string(),
      language: z.string(),
    });

    const completion = await openai.beta.chat.completions.parse({
      model: "gpt-4o-2024-08-06",
      messages: [
        { role: "system", content: "Enhance the song information." },
        { role: "user", content: JSON.stringify(songMetadata) },
      ],
      response_format: zodResponseFormat(EnhancedSong, "song"),
    });

    const enhancedSong = completion.choices[0].message.parsed;

    console.log('Enhanced song:', enhancedSong);
    res.status(200).json(enhancedSong);
  });
}