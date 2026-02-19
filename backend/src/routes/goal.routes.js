import { Router } from 'express';
import goalController from '../controllers/goal.controller.js';

const router = Router();

router.get('/', goalController.getAllGoals.bind(goalController));
router.get('/active', goalController.getActiveGoals.bind(goalController));
router.get('/:id', goalController.getGoalById.bind(goalController));
router.post('/', goalController.createGoal.bind(goalController));
router.put('/:id', goalController.updateGoal.bind(goalController));
router.post('/:id/progress', goalController.updateProgress.bind(goalController));
router.delete('/:id', goalController.deleteGoal.bind(goalController));

export default router;
