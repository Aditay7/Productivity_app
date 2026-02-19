import { Router } from 'express';
import analyticsController from '../controllers/analytics.controller.js';

const router = Router();

router.get('/dashboard', analyticsController.getProductivityDashboard.bind(analyticsController));
router.get('/habits', analyticsController.getHabitStats.bind(analyticsController));
router.post('/habits/:templateId/complete', analyticsController.completeHabit.bind(analyticsController));

export default router;
