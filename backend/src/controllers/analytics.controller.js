import analyticsService from '../services/analytics.service.js';

export class AnalyticsController {
    /**
     * GET /api/analytics/dashboard
     */
    async getProductivityDashboard(req, res, next) {
        try {
            const dashboard = await analyticsService.getProductivityDashboard();
            res.json({
                success: true,
                data: dashboard,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/analytics/habits
     */
    async getHabitStats(req, res, next) {
        try {
            const habits = await analyticsService.getHabitStats();
            res.json({
                success: true,
                data: habits,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/analytics/habits/:templateId/complete
     */
    async completeHabit(req, res, next) {
        try {
            const template = await analyticsService.updateHabitCompletion(req.params.templateId);
            res.json({
                success: true,
                data: template,
                message: 'Habit completion recorded',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new AnalyticsController();
