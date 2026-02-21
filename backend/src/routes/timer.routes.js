import { Router } from 'express';
import timerController from '../controllers/timer.controller.js';

const router = Router();

router.post('/start', timerController.startTimer.bind(timerController));
router.post('/:id/complete', timerController.completeTimer.bind(timerController));
router.post('/:id/fail', timerController.failTimer.bind(timerController));
router.get('/history', timerController.getHistory.bind(timerController));
router.get('/active', timerController.getActiveSession.bind(timerController));

export default router;
