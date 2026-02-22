import playerService from '../services/player.service.js';

export class PlayerController {
    /**
     * GET /api/player
     */
    async getPlayer(req, res, next) {
        try {
            const player = await playerService.getPlayer(req.user.id);
            res.json({
                success: true,
                data: player,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * PUT /api/player
     */
    async updatePlayer(req, res, next) {
        try {
            const player = await playerService.updatePlayer(req.user.id, req.body);
            res.json({
                success: true,
                data: player,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/player/add-xp
     */
    async addXP(req, res, next) {
        try {
            const { xp, statType } = req.body;
            const player = await playerService.addXP(req.user.id, xp, statType);
            res.json({
                success: true,
                data: player,
                message: `Added ${xp} XP to ${statType}`,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/player/toggle-shadow-mode
     */
    async toggleShadowMode(req, res, next) {
        try {
            const { enable } = req.body;
            const player = await playerService.toggleShadowMode(req.user.id, enable);
            res.json({
                success: true,
                data: player,
                message: `Shadow Mode ${enable ? 'enabled' : 'disabled'}`,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/player/reset
     */
    async resetPlayer(req, res, next) {
        try {
            const player = await playerService.resetPlayer(req.user.id);
            res.json({
                success: true,
                data: player,
                message: 'Player reset successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new PlayerController();
