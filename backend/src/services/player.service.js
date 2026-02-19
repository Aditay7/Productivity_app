import { Player } from '../models/Player.js';
import { calculateLevel, calculateStreak } from '../utils/calculations.js';

export class PlayerService {
    /**
     * Get player or create if doesn't exist
     */
    async getPlayer() {
        let player = await Player.findOne();

        if (!player) {
            player = await Player.create({
                level: 1,
                totalXp: 0,
                strength: 0,
                intelligence: 0,
                discipline: 0,
                wealth: 0,
                charisma: 0,
                currentStreak: 0,
            });
        }

        return player;
    }

    /**
     * Update player stats
     */
    async updatePlayer(data) {
        const player = await this.getPlayer();
        Object.assign(player, data);
        player.updatedAt = new Date();
        await player.save();
        return player;
    }

    /**
     * Add XP to player and update stats
     */
    async addXP(xp, statType) {
        const player = await this.getPlayer();

        // Calculate new streak
        const newStreak = calculateStreak(player.lastActivityDate, player.currentStreak);

        // Calculate new XP and level
        const newTotalXp = player.totalXp + xp;
        const newLevel = calculateLevel(newTotalXp);

        // Update player
        player.totalXp = newTotalXp;
        player.level = newLevel;
        player.currentStreak = newStreak;
        player.lastActivityDate = new Date();
        player[statType] = player[statType] + xp;

        await player.save();
        return player;
    }

    /**
     * Toggle Shadow Mode
     */
    async toggleShadowMode(enable) {
        const player = await this.getPlayer();
        player.isShadowMode = enable;
        player.shadowModeActivatedAt = enable ? new Date() : null;
        await player.save();
        return player;
    }

    /**
     * Reset player (for testing)
     */
    async resetPlayer() {
        await Player.deleteMany({});
        return await Player.create({
            level: 1,
            totalXp: 0,
            strength: 0,
            intelligence: 0,
            discipline: 0,
            wealth: 0,
            charisma: 0,
            currentStreak: 0,
        });
    }
}

export default new PlayerService();
