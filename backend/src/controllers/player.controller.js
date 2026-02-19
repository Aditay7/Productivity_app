import playerService from '../services/player.service.js';

export class PlayerController {
    /**
     * GET /api/player
     */
    async getPlayer(_req, res, next) {
        try {
            const player = await playerService.getPlayer();
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
            const player = await playerService.updatePlayer(req.body);
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
            const player = await playerService.addXP(xp, statType);
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
            const player = await playerService.toggleShadowMode(enable);
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
    async resetPlayer(_req, res, next) {
        try {
            const player = await playerService.resetPlayer();
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
