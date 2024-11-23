import express from 'express';
import bodyParser from 'body-parser';
import { identifySong } from './IdentifySong.js';
import { downloadSong } from './DownloadSong.js';
import { searchSong } from './SearchSong.js';
import { enhanceSong } from './EnhanceSong.js';

const app = express();
const port = 3000;

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// POST route /identify
identifySong(app);
// POST route /download
downloadSong(app);
// POST route /search
searchSong(app);
// POST route /enhance
enhanceSong(app);

// Start the server
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});
