import ytdl from "@distube/ytdl-core";
import { Transform } from 'stream';

// POST route /download
export function downloadSong(app) {
  app.post('/download', async (req, res) => {
      let url = req.body.url;
      let filename = req.body.filename;
      let simulatedDelay = req.body.simulatedDelay;
      try {
        let readable = ytdl(url, { filter: 'videoandaudio' });

        readable.on('progress', (chunkLength, downloaded, total) => {
            console.log(`downloading... ${downloaded/total} ${downloaded} ${total}`);
        });
        readable.on('end', () => {
            console.log('done...');
            console.log("Filename: " + filename);
        });

        res.setHeader('Content-Disposition', `attachment; filename=${filename}`);

        // Create a transform stream to introduce delay
        if(simulatedDelay) {
            const mbps = simulatedDelay; // in Mbps
            const slowStream = new Transform({
              transform(chunk, encoding, callback) {
                const chunkSizeInBits = chunk.length * 8;
                const delay = (chunkSizeInBits / (mbps * 1024 * 1024)) * 1000; // 5 Mbps in milliseconds
                // console.log(`Delay: ${delay} ms`);
                setTimeout(() => {
                  callback(null, chunk);
                }, delay);
              }
            });
            readable.pipe(slowStream).pipe(res);
        } else {
            readable.pipe(res);
        }


      } catch (error) {
          console.error(error);
          res.status(500).send({
              success: false,
              message: error,
          });
      }
  });
}