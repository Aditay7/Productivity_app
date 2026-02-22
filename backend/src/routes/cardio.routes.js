import express from 'express';
import { syncDailyLogs, getAnalyticsSummary, saveWorkout } from '../controllers/cardio.controller.js';

const router = express.Router();

// Daily Step Logs Sync
router.post('/daily-logs/sync', syncDailyLogs);

// Analytics Dashboard
router.get('/analytics/summary', getAnalyticsSummary);

// Explicit Workouts
router.post('/workouts', saveWorkout);

export default router;
