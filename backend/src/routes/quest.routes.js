import { Router } from 'express';
import questController from '../controllers/quest.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = Router();

router.use(protect); // Secure all endpoints

// Standard quest routes
router.get('/', questController.getAllQuests.bind(questController));
router.get('/today', questController.getTodayQuests.bind(questController));
router.get('/overdue', questController.getOverdueQuests.bind(questController));
router.get('/due-soon', questController.getDueSoonQuests.bind(questController));
router.get('/:id', questController.getQuestById.bind(questController));
router.post('/', questController.createQuest.bind(questController));
router.put('/:id', questController.updateQuest.bind(questController));
router.post('/:id/complete', questController.completeQuest.bind(questController));
router.post('/:id/complete-with-timer', questController.completeQuestWithTimer.bind(questController));
router.delete('/:id', questController.deleteQuest.bind(questController));

// Timer routes
router.post('/:id/timer/start', questController.startTimer.bind(questController));
router.post('/:id/timer/pause', questController.pauseTimer.bind(questController));
router.post('/:id/timer/resume', questController.resumeTimer.bind(questController));
router.post('/:id/timer/stop', questController.stopTimer.bind(questController));

export default router;
