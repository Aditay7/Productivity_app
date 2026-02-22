import { Router } from 'express';
import analyticsController from '../controllers/analytics.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = Router();

router.use(protect); // Secure all endpoints

router.get('/dashboard', analyticsController.getProductivityDashboard.bind(analyticsController));
router.get('/habits', analyticsController.getHabitStats.bind(analyticsController));
router.post('/habits/:templateId/complete', analyticsController.completeHabit.bind(analyticsController));

export default router;
