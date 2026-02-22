import { TimerSession } from '../models/TimerSession.js';
import playerService from './player.service.js';
import { AppError } from '../middleware/error.middleware.js';

export class TimerService {

    async startTimer(userId, data) {
        // Prevent multiple active raids for the same user
        const activeTimer = await TimerSession.findOne({ userId, status: 'active' });
        if (activeTimer) {
            throw new AppError(400, 'You already have an active Dungeon Raid!');
        }

        const { durationMinutes, rank } = data;
        return await TimerSession.create({
            userId,
            durationMinutes,
            rank,
            status: 'active'
        });
    }

    async completeTimer(userId, sessionId) {
        const session = await TimerSession.findOne({ _id: sessionId, userId });
        if (!session) throw new AppError(404, 'Timer session not found or unauthorized');
        if (session.status !== 'active') throw new AppError(400, 'Session is not active');

        // Determine XP
        let xpReward = 0;
        switch (session.rank) {
            case 'E': xpReward = 50; break;
            case 'C': xpReward = 150; break;
            case 'A': xpReward = 300; break;
            case 'S': xpReward = 500; break;
            default: xpReward = 50;
        }

        session.status = 'completed';
        session.xpEarned = xpReward;
        session.endedAt = new Date();
        await session.save();

        // Grant XP to intelligence for deep work (Scoped to the User)
        await playerService.addXP(userId, xpReward, 'intelligence');

        return session;
    }

    async failTimer(userId, sessionId) {
        const session = await TimerSession.findOne({ _id: sessionId, userId });
        if (!session) throw new AppError(404, 'Timer session not found or unauthorized');
        if (session.status !== 'active') throw new AppError(400, 'Session is not active');

        session.status = 'failed';
        session.endedAt = new Date();
        await session.save();

        return session;
    }

    async getHistory(userId) {
        return await TimerSession.find({ userId }).sort({ startedAt: -1 }).limit(50);
    }

    async getActiveSession(userId) {
        return await TimerSession.findOne({ userId, status: 'active' });
    }
}

export default new TimerService();
