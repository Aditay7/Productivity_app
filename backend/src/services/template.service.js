import { QuestTemplate } from '../models/QuestTemplate.js';
import { AppError } from '../middleware/error.middleware.js';

export class TemplateService {
    /**
     * Create a new quest template
     */
    async createTemplate(data) {
        return await QuestTemplate.create(data);
    }

    /**
     * Get all templates
     */
    async getAllTemplates(activeOnly = false) {
        const query = activeOnly ? { isActive: true } : {};

        return await QuestTemplate.find(query).sort({ createdAt: -1 });
    }

    /**
     * Get template by ID
     */
    async getTemplateById(id) {
        const template = await QuestTemplate.findById(id);

        if (!template) {
            throw new AppError(404, 'Template not found');
        }

        return template;
    }

    /**
     * Update template
     */
    async updateTemplate(id, data) {
        const template = await QuestTemplate.findByIdAndUpdate(id, data, { new: true });

        if (!template) {
            throw new AppError(404, 'Template not found');
        }

        return template;
    }

    /**
     * Toggle template active status
     */
    async toggleTemplate(id) {
        const template = await this.getTemplateById(id);
        template.isActive = !template.isActive;
        await template.save();
        return template;
    }

    /**
     * Delete template
     */
    async deleteTemplate(id) {
        const template = await QuestTemplate.findByIdAndDelete(id);

        if (!template) {
            throw new AppError(404, 'Template not found');
        }
    }
}

export default new TemplateService();
