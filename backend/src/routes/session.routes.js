import { Router } from 'express';
import sessionController from '../controllers/session.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = Router();

router.use(protect); // Secure all endpoints

router.get('/quest/:questId', sessionController.getQuestSessions.bind(sessionController));
router.get('/stats', sessionController.getSessionStats.bind(sessionController));
router.post('/', sessionController.createSession.bind(sessionController));

export default router;
