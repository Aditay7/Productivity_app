import questService from '../services/quest.service.js';
import playerService from '../services/player.service.js';

export class QuestController {
    /**
     * GET /api/quests
     */
    async getAllQuests(req, res, next) {
        try {
            const filters = {
                isCompleted: req.query.isCompleted === 'true' ? true : req.query.isCompleted === 'false' ? false : undefined,
                statType: req.query.statType,
                templateId: req.query.templateId,
                startDate: req.query.startDate,
                endDate: req.query.endDate,
            };

            const quests = await questService.getAllQuests(filters);
            res.json({
                success: true,
                data: quests,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/quests/today
     */
    async getTodayQuests(_req, res, next) {
        try {
            const quests = await questService.getTodayQuests();
            res.json({
                success: true,
                data: quests,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/quests/overdue
     */
    async getOverdueQuests(_req, res, next) {
        try {
            const quests = await questService.getOverdueQuests();
            res.json({
                success: true,
                data: quests,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/quests/due-soon
     */
    async getDueSoonQuests(_req, res, next) {
        try {
            const quests = await questService.getDueSoonQuests();
            res.json({
                success: true,
                data: quests,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/quests/:id
     */
    async getQuestById(req, res, next) {
        try {
            const quest = await questService.getQuestById(req.params.id);
            res.json({
                success: true,
                data: quest,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests
     */
    async createQuest(req, res, next) {
        try {
            const quest = await questService.createQuest(req.body);
            res.status(201).json({
                success: true,
                data: quest,
                message: 'Quest created successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * PUT /api/quests/:id
     */
    async updateQuest(req, res, next) {
        try {
            const quest = await questService.updateQuest(req.params.id, req.body);
            res.json({
                success: true,
                data: quest,
                message: 'Quest updated successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/complete
     */
    async completeQuest(req, res, next) {
        try {
            const result = await questService.completeQuest(req.params.id);

            res.json({
                success: true,
                data: result.quest,
                skillResult: result.skillResult,
                message: 'Quest completed successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/complete-with-timer
     */
    async completeQuestWithTimer(req, res, next) {
        try {
            const quest = await questService.completeQuestWithTimer(req.params.id, req.body.focusRating);
            res.json({
                success: true,
                data: quest,
                message: 'Quest completed with timer data',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/timer/start
     */
    async startTimer(req, res, next) {
        try {
            const quest = await questService.startQuestTimer(req.params.id);
            res.json({
                success: true,
                data: quest,
                message: 'Timer started',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/timer/pause
     */
    async pauseTimer(req, res, next) {
        try {
            const quest = await questService.pauseQuestTimer(req.params.id);
            res.json({
                success: true,
                data: quest,
                message: 'Timer paused',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/timer/resume
     */
    async resumeTimer(req, res, next) {
        try {
            const quest = await questService.resumeQuestTimer(req.params.id);
            res.json({
                success: true,
                data: quest,
                message: 'Timer resumed',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/quests/:id/timer/stop
     */
    async stopTimer(req, res, next) {
        try {
            const quest = await questService.stopQuestTimer(req.params.id, req.body.focusRating);
            res.json({
                success: true,
                data: quest,
                message: 'Timer stopped',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * DELETE /api/quests/:id
     */
    async deleteQuest(req, res, next) {
        try {
            await questService.deleteQuest(req.params.id);
            res.json({
                success: true,
                message: 'Quest deleted successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new QuestController();
