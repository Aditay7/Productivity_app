import templateService from '../services/template.service.js';

export class TemplateController {
    /**
     * GET /api/templates
     */
    async getAllTemplates(req, res, next) {
        try {
            const activeOnly = req.query.activeOnly === 'true';
            const templates = await templateService.getAllTemplates(req.user.id, activeOnly);
            res.json({
                success: true,
                data: templates,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/templates/:id
     */
    async getTemplateById(req, res, next) {
        try {
            const template = await templateService.getTemplateById(req.user.id, req.params.id);
            res.json({
                success: true,
                data: template,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/templates
     */
    async createTemplate(req, res, next) {
        try {
            const template = await templateService.createTemplate(req.user.id, req.body);
            res.status(201).json({
                success: true,
                data: template,
                message: 'Template created successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * PUT /api/templates/:id
     */
    async updateTemplate(req, res, next) {
        try {
            const template = await templateService.updateTemplate(req.user.id, req.params.id, req.body);
            res.json({
                success: true,
                data: template,
                message: 'Template updated successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/templates/:id/toggle
     */
    async toggleTemplate(req, res, next) {
        try {
            const template = await templateService.toggleTemplate(req.user.id, req.params.id);
            res.json({
                success: true,
                data: template,
                message: `Template ${template.isActive ? 'activated' : 'deactivated'}`,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * DELETE /api/templates/:id
     */
    async deleteTemplate(req, res, next) {
        try {
            await templateService.deleteTemplate(req.user.id, req.params.id);
            res.json({
                success: true,
                message: 'Template deleted successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new TemplateController();
