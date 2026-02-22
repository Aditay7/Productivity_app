import { Router } from 'express';
import templateController from '../controllers/template.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = Router();

router.use(protect); // Secure all endpoints

router.get('/', templateController.getAllTemplates.bind(templateController));
router.get('/:id', templateController.getTemplateById.bind(templateController));
router.post('/', templateController.createTemplate.bind(templateController));
router.put('/:id', templateController.updateTemplate.bind(templateController));
router.post('/:id/toggle', templateController.toggleTemplate.bind(templateController));
router.delete('/:id', templateController.deleteTemplate.bind(templateController));

export default router;
