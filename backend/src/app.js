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
import authRoutes from './routes/auth.routes.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

// Load environment variables (for local dev; Lambda uses env vars from serverless.yml)
dotenv.config();

const app = express();

// Connect to MongoDB (cached connection for Lambda warm starts)
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
        environment: process.env.NODE_ENV || 'development',
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
app.use('/api/auth', authRoutes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
