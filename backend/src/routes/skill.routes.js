import express from 'express';
import skillController from '../controllers/skill.controller.js';

const router = express.Router();

// Skill routes
router.get('/', skillController.getAllSkills);
router.get('/:name', skillController.getSkillByName);
router.post('/initialize', skillController.initializeSkills);

// Perk routes
router.get('/perks/all', skillController.getAllPerks);
router.get('/perks/unlocked', skillController.getUnlockedPerks);
router.get('/perks/skill/:skillName', skillController.getPerksBySkill);
router.post('/perks/initialize', skillController.initializePerks);

export default router;
