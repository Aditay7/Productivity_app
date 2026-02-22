import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import connectDB from './utils/db.js';
import playerRoutes from './routes/player.routes.js';
import questRoutes from './routes/quest.routes.js';
import templateRoutes from './routes/template.routes.js';
import analyticsRoutes from './routes/analytics.routes.js';
import goalRoutes from './routes/goal.routes.js';
import skillRoutes from './routes/skill.routes.js';
import sessionRoutes from './routes/session.routes.js';
import timerRoutes from './routes/timer.routes.js';
import cardioRoutes from './routes/cardio.routes.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (_req, res) => {
    res.json({
        success: true,
        message: 'Solo Leveling API is running',
        timestamp: new Date().toISOString(),
    });
});

// API Routes
app.use('/api/player', playerRoutes);
app.use('/api/quests', questRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/skills', skillRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/timer', timerRoutes);
app.use('/api/cardio', cardioRoutes);


// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🎮 Solo Leveling API ready!`);
});

export default app;
