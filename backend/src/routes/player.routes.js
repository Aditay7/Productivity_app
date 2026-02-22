import { Router } from 'express';
import playerController from '../controllers/player.controller.js';

import { protect } from '../middleware/auth.middleware.js';

const router = Router();

router.use(protect); // Apply to all routes below

router.get('/', playerController.getPlayer.bind(playerController));
router.put('/', playerController.updatePlayer.bind(playerController));
router.post('/add-xp', playerController.addXP.bind(playerController));
router.post('/toggle-shadow-mode', playerController.toggleShadowMode.bind(playerController));
router.post('/reset', playerController.resetPlayer.bind(playerController));

export default router;
