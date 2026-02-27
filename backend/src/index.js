// Local development entry point.
// Lambda uses handler.cjs instead — this file is only for `npm run dev` / `npm start`.
import dotenv from 'dotenv';
dotenv.config();

import app from './app.js';

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🎮 Solo Leveling API ready!`);
});
