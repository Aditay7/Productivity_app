import { TimerSession } from '../models/TimerSession.js';
import { PlayerService } from './player.service.js';
import { AppError } from '../middleware/error.middleware.js';

const playerService = new PlayerService();

export class TimerService {

    async startTimer(data) {
        // Prevent multiple active raids
        const activeTimer = await TimerSession.findOne({ status: 'active' });
        if (activeTimer) {
            throw new AppError(400, 'You already have an active Dungeon Raid!');
        }

        const { durationMinutes, rank } = data;
        return await TimerSession.create({
            durationMinutes,
            rank,
            status: 'active'
        });
    }

    async completeTimer(sessionId) {
        const session = await TimerSession.findById(sessionId);
        if (!session) throw new AppError(404, 'Timer session not found');
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

        // Grant XP to intelligence for deep work
        await playerService.addXP(xpReward, 'intelligence');

        return session;
    }

    async failTimer(sessionId) {
        const session = await TimerSession.findById(sessionId);
        if (!session) throw new AppError(404, 'Timer session not found');
        if (session.status !== 'active') throw new AppError(400, 'Session is not active');

        session.status = 'failed';
        session.endedAt = new Date();
        await session.save();

        return session;
    }

    async getHistory() {
        return await TimerSession.find().sort({ startedAt: -1 }).limit(50);
    }

    async getActiveSession() {
        return await TimerSession.findOne({ status: 'active' });
    }
}

export default new TimerService();
