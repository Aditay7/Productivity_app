import timerService from '../services/timer.service.js';

export class TimerController {

    async startTimer(req, res, next) {
        try {
            const session = await timerService.startTimer(req.body);
            res.status(201).json({
                success: true,
                data: session,
                message: 'Dungeon Raid Initiated'
            });
        } catch (error) {
            next(error);
        }
    }

    async completeTimer(req, res, next) {
        try {
            const session = await timerService.completeTimer(req.params.id);
            res.json({
                success: true,
                data: session,
                message: 'Boss Defeated! XP Granted.'
            });
        } catch (error) {
            next(error);
        }
    }

    async failTimer(req, res, next) {
        try {
            const session = await timerService.failTimer(req.params.id);
            res.json({
                success: true,
                data: session,
                message: 'Raid Failed. Zero XP.'
            });
        } catch (error) {
            next(error);
        }
    }

    async getHistory(req, res, next) {
        try {
            const history = await timerService.getHistory();
            res.json({
                success: true,
                data: history
            });
        } catch (error) {
            next(error);
        }
    }

    async getActiveSession(req, res, next) {
        try {
            const session = await timerService.getActiveSession();
            res.json({
                success: true,
                data: session
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new TimerController();
