import express from 'express';
import { syncDailyLogs, getAnalyticsSummary, saveWorkout } from '../controllers/cardio.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(protect); // Secure all endpoints

// Daily Step Logs Sync
router.post('/daily-logs/sync', syncDailyLogs);

// Analytics Dashboard
router.get('/analytics/summary', getAnalyticsSummary);

// Explicit Workouts
router.post('/workouts', saveWorkout);

export default router;
