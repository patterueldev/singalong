import ytsr from "@distube/ytsr";

// POST route /search
export function searchSong(app) {
  app.get('/search', async (req, res) => {
    let keyword = req.query.keyword
    let limit = req.query.limit ?? 20
    console.log(`Searching for ${keyword}`);
    let result = await ytsr(keyword, { safeSearch: true, limit: limit, type: 'video' })
    res.status(200).json(result.items)
  });
}