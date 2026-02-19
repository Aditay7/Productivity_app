import { QuestSession } from '../models/QuestSession.js';
import { AppError } from '../middleware/error.middleware.js';

export class SessionService {
    /**
     * Create a new quest session
     */
    async createSession(questId, sessionData) {
        const session = await QuestSession.create({
            questId,
            ...sessionData
        });
        return session;
    }

    /**
     * Get all sessions for a quest
     */
    async getQuestSessions(questId) {
        return await QuestSession.find({ questId })
            .sort({ createdAt: -1 });
    }

    /**
     * Get session statistics
     */
    async getSessionStats(filters = {}) {
        const query = {};

        if (filters.questId) {
            query.questId = filters.questId;
        }

        if (filters.startDate || filters.endDate) {
            query.createdAt = {};
            if (filters.startDate) {
                query.createdAt.$gte = new Date(filters.startDate);
            }
            if (filters.endDate) {
                query.createdAt.$lte = new Date(filters.endDate);
            }
        }

        const sessions = await QuestSession.find(query);

        if (sessions.length === 0) {
            return {
                totalSessions: 0,
                totalDuration: 0,
                averageDuration: 0,
                averageFocusRating: 0,
                totalPauses: 0
            };
        }

        const totalDuration = sessions.reduce((sum, s) => sum + (s.durationMinutes || 0), 0);
        const totalPauses = sessions.reduce((sum, s) => sum + (s.pauseCount || 0), 0);
        const ratingsCount = sessions.filter(s => s.focusRating).length;
        const totalRating = sessions.reduce((sum, s) => sum + (s.focusRating || 0), 0);

        return {
            totalSessions: sessions.length,
            totalDuration,
            averageDuration: Math.round(totalDuration / sessions.length),
            averageFocusRating: ratingsCount > 0 ? (totalRating / ratingsCount).toFixed(1) : 0,
            totalPauses
        };
    }

    /**
     * Update session
     */
    async updateSession(sessionId, data) {
        const session = await QuestSession.findByIdAndUpdate(
            sessionId,
            data,
            { new: true }
        );

        if (!session) {
            throw new AppError(404, 'Session not found');
        }

        return session;
    }

    /**
     * Delete session
     */
    async deleteSession(sessionId) {
        const session = await QuestSession.findByIdAndDelete(sessionId);

        if (!session) {
            throw new AppError(404, 'Session not found');
        }
    }
}

export default new SessionService();
