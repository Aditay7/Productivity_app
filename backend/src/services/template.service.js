import { QuestTemplate } from '../models/QuestTemplate.js';
import { AppError } from '../middleware/error.middleware.js';

export class TemplateService {
    /**
     * Create a new quest template
     */
    async createTemplate(userId, data) {
        return await QuestTemplate.create({ ...data, userId });
    }

    /**
     * Get all templates
     */
    async getAllTemplates(userId, activeOnly = false) {
        const query = { userId };
        if (activeOnly) {
            query.isActive = true;
        }

        return await QuestTemplate.find(query).sort({ createdAt: -1 });
    }

    /**
     * Get template by ID
     */
    async getTemplateById(userId, id) {
        const template = await QuestTemplate.findOne({ _id: id, userId });

        if (!template) {
            throw new AppError(404, 'Template not found or unauthorized');
        }

        return template;
    }

    /**
     * Update template
     */
    async updateTemplate(userId, id, data) {
        const template = await QuestTemplate.findOneAndUpdate(
            { _id: id, userId },
            data,
            { new: true }
        );

        if (!template) {
            throw new AppError(404, 'Template not found or unauthorized');
        }

        return template;
    }

    /**
     * Toggle template active status
     */
    async toggleTemplate(userId, id) {
        const template = await this.getTemplateById(userId, id);
        template.isActive = !template.isActive;
        await template.save();
        return template;
    }

    /**
     * Delete template
     */
    async deleteTemplate(userId, id) {
        const template = await QuestTemplate.findOneAndDelete({ _id: id, userId });

        if (!template) {
            throw new AppError(404, 'Template not found or unauthorized');
        }
    }
}

export default new TemplateService();
