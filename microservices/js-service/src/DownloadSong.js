import ytdl from "@distube/ytdl-core";

// POST route /download
export function downloadSong(app) {
  app.post('/download', async (req, res) => {
      let url = req.body.url
      let filename = req.body.filename
      let readable = ytdl(url, { filter: 'videoandaudio' })
      try {
          res.setHeader('Content-Disposition', `attachment; filename=${filename}`)
          readable.pipe(res)
      } catch (error) {
          console.error(error)
          res.status(500).send({
              success: false,
              message: error,
          })
      }
  })
}
