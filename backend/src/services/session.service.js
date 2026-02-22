import { QuestSession } from '../models/QuestSession.js';
import { AppError } from '../middleware/error.middleware.js';

export class SessionService {
    /**
     * Create a new quest session
     */
    async createSession(userId, questId, sessionData) {
        const session = await QuestSession.create({
            userId,
            questId,
            ...sessionData
        });
        return session;
    }

    /**
     * Get all sessions for a quest
     */
    async getQuestSessions(userId, questId) {
        return await QuestSession.find({ questId, userId })
            .sort({ createdAt: -1 });
    }

    /**
     * Get session statistics
     */
    async getSessionStats(userId, filters = {}) {
        const query = { userId };

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
    async updateSession(userId, sessionId, data) {
        const session = await QuestSession.findOneAndUpdate(
            { _id: sessionId, userId },
            data,
            { new: true }
        );

        if (!session) {
            throw new AppError(404, 'Session not found or unauthorized');
        }

        return session;
    }

    /**
     * Delete session
     */
    async deleteSession(userId, sessionId) {
        const session = await QuestSession.findOneAndDelete({ _id: sessionId, userId });

        if (!session) {
            throw new AppError(404, 'Session not found or unauthorized');
        }
    }
}

export default new SessionService();
