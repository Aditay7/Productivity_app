import sessionService from '../services/session.service.js';

export class SessionController {
    /**
     * GET /api/sessions/quest/:questId
     */
    async getQuestSessions(req, res, next) {
        try {
            const sessions = await sessionService.getQuestSessions(req.params.questId);
            res.json({
                success: true,
                data: sessions,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/sessions/stats
     */
    async getSessionStats(req, res, next) {
        try {
            const filters = {
                questId: req.query.questId,
                startDate: req.query.startDate,
                endDate: req.query.endDate,
            };

            const stats = await sessionService.getSessionStats(filters);
            res.json({
                success: true,
                data: stats,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/sessions
     */
    async createSession(req, res, next) {
        try {
            const { questId, ...sessionData } = req.body;
            const session = await sessionService.createSession(questId, sessionData);
            res.status(201).json({
                success: true,
                data: session,
                message: 'Session created successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new SessionController();
