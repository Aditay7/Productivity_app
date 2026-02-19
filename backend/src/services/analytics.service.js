import { Quest } from '../models/Quest.js';
import { QuestTemplate } from '../models/QuestTemplate.js';
import { Player } from '../models/Player.js';

export class AnalyticsService {
    /**
     * Get productivity dashboard data
     */
    async getProductivityDashboard() {
        const completedQuests = await Quest.find({ isCompleted: true }).sort({ dateCompleted: 1 });
        const player = await Player.findOne();

        return {
            bestCompletionTimes: await this.getBestCompletionTimes(completedQuests),
            productivityPatterns: await this.getProductivityPatterns(completedQuests),
            questsByDifficulty: await this.getQuestsByDifficulty(completedQuests),
            statBalance: await this.getStatBalance(player),
            weeklyProgress: await this.getWeeklyProgress(),
            monthlyProgress: await this.getMonthlyProgress()
        };
    }

    /**
     * Get best completion times (hours of day)
     */
    async getBestCompletionTimes(quests) {
        const hourCounts = new Array(24).fill(0);
        
        quests.forEach(quest => {
            if (quest.completionTimeOfDay !== null) {
                hourCounts[quest.completionTimeOfDay]++;
            }
        });

        const maxCount = Math.max(...hourCounts);
        const bestHours = hourCounts
            .map((count, hour) => ({ hour, count }))
            .filter(h => h.count > 0)
            .sort((a, b) => b.count - a.count)
            .slice(0, 3);

        return {
            hourlyDistribution: hourCounts,
            bestHours,
            recommendation: bestHours[0] ? this._getTimeRecommendation(bestHours[0].hour) : null
        };
    }

    /**
     * Get productivity patterns
     */
    async getProductivityPatterns(quests) {
        const dayOfWeekCounts = new Array(7).fill(0); // 0 = Sunday
        const last30Days = new Date();
        last30Days.setDate(last30Days.getDate() - 30);

        quests.forEach(quest => {
            if (quest.dateCompleted && quest.dateCompleted >= last30Days) {
                const dayOfWeek = quest.dateCompleted.getDay();
                dayOfWeekCounts[dayOfWeek]++;
            }
        });

        const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const patterns = dayOfWeekCounts.map((count, index) => ({
            day: dayNames[index],
            dayIndex: index,
            count
        })).sort((a, b) => b.count - a.count);

        return {
            weeklyPattern: patterns,
            mostProductiveDay: patterns[0],
            leastProductiveDay: patterns[patterns.length - 1]
        };
    }

    /**
     * Get quests by difficulty with success rates
     */
    async getQuestsByDifficulty(quests) {
        const difficulties = [1, 2, 3, 4]; // Easy, Medium, Hard, Expert
        const stats = {};

        difficulties.forEach(diff => {
            const questsOfDifficulty = quests.filter(q => q.difficulty === diff);
            stats[diff] = {
                completed: questsOfDifficulty.length,
                totalTime: questsOfDifficulty.reduce((sum, q) => sum + q.timeMinutes, 0),
                averageTime: questsOfDifficulty.length > 0 
                    ? Math.round(questsOfDifficulty.reduce((sum, q) => sum + q.timeMinutes, 0) / questsOfDifficulty.length)
                    : 0
            };
        });

        return stats;
    }

    /**
     * Get stat balance
     */
    async getStatBalance(player) {
        if (!player) return null;

        const stats = {
            strength: player.strength,
            intelligence: player.intelligence,
            discipline: player.discipline,
            wealth: player.wealth,
            charisma: player.charisma
        };

        const total = Object.values(stats).reduce((sum, val) => sum + val, 0);
        const average = total / 5;
        const mostDeveloped = Object.keys(stats).reduce((a, b) => stats[a] > stats[b] ? a : b);
        const leastDeveloped = Object.keys(stats).reduce((a, b) => stats[a] < stats[b] ? a : b);

        return {
            stats,
            total,
            average: Math.round(average),
            mostDeveloped,
            leastDeveloped,
            balance: this._calculateBalance(stats)
        };
    }

    /**
     * Get weekly progress
     */
    async getWeeklyProgress() {
        const weekStart = new Date();
        weekStart.setDate(weekStart.getDate() - weekStart.getDay()); // Start of week (Sunday)
        weekStart.setHours(0, 0, 0, 0);

        const completedThisWeek = await Quest.countDocuments({
            isCompleted: true,
            dateCompleted: { $gte: weekStart }
        });

        const totalXpThisWeek = await Quest.aggregate([
            { $match: { isCompleted: true, dateCompleted: { $gte: weekStart } } },
            { $group: { _id: null, totalXp: { $sum: '$xpReward' } } }
        ]);

        return {
            questsCompleted: completedThisWeek,
            xpEarned: totalXpThisWeek[0]?.totalXp || 0,
            weekStart: weekStart.toISOString()
        };
    }

    /**
     * Get monthly progress
     */
    async getMonthlyProgress() {
        const monthStart = new Date();
        monthStart.setDate(1);
        monthStart.setHours(0, 0, 0, 0);

        const completedThisMonth = await Quest.countDocuments({
            isCompleted: true,
            dateCompleted: { $gte: monthStart }
        });

        const totalXpThisMonth = await Quest.aggregate([
            { $match: { isCompleted: true, dateCompleted: { $gte: monthStart } } },
            { $group: { _id: null, totalXp: { $sum: '$xpReward' } } }
        ]);

        return {
            questsCompleted: completedThisMonth,
            xpEarned: totalXpThisMonth[0]?.totalXp || 0,
            monthStart: monthStart.toISOString()
        };
    }

    /**
     * Get habit statistics
     */
    async getHabitStats() {
        const habits = await QuestTemplate.find({ isHabit: true });
        
        const habitStats = habits.map(habit => {
            const completionRate = this._calculateHabitCompletionRate(habit);
            return {
                id: habit._id,
                title: habit.title,
                streak: habit.habitStreak,
                completionRate,
                lastCompleted: habit.habitLastCompletedDate,
                totalCompletions: habit.habitCompletionHistory?.length || 0
            };
        });

        return habitStats;
    }

    /**
     * Update habit completion
     */
    async updateHabitCompletion(templateId) {
        const template = await QuestTemplate.findById(templateId);
        if (!template || !template.isHabit) {
            throw new Error('Template is not a habit');
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Check if already completed today
        const lastCompleted = template.habitLastCompletedDate 
            ? new Date(template.habitLastCompletedDate) 
            : null;
        
        if (lastCompleted) {
            lastCompleted.setHours(0, 0, 0, 0);
            if (lastCompleted.getTime() === today.getTime()) {
                return template; // Already completed today
            }
        }

        // Update streak
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        
        if (lastCompleted && lastCompleted.getTime() === yesterday.getTime()) {
            template.habitStreak += 1;
        } else {
            template.habitStreak = 1; // Reset if broken
        }

        template.habitLastCompletedDate = new Date();
        if (!template.habitCompletionHistory) {
            template.habitCompletionHistory = [];
        }
        template.habitCompletionHistory.push(new Date());

        await template.save();
        return template;
    }

    // Helper methods
    _getTimeRecommendation(hour) {
        if (hour < 12) return `You're most productive in the morning (${hour}:00 AM)`;
        if (hour < 17) return `You're most productive in the afternoon (${hour % 12}:00 PM)`;
        return `You're most productive in the evening (${hour % 12}:00 PM)`;
    }

    _calculateBalance(stats) {
        const values = Object.values(stats);
        const avg = values.reduce((sum, val) => sum + val, 0) / values.length;
        const variance = values.reduce((sum, val) => sum + Math.pow(val - avg, 2), 0) / values.length;
        const stdDev = Math.sqrt(variance);
        
        // Lower stdDev = better balance
        if (stdDev < 100) return 'Excellent';
        if (stdDev < 300) return 'Good';
        if (stdDev < 500) return 'Fair';
        return 'Unbalanced';
    }

    _calculateHabitCompletionRate(habit) {
        if (!habit.habitCompletionHistory || habit.habitCompletionHistory.length === 0) {
            return 0;
        }

        const daysSinceCreation = Math.floor(
            (new Date() - habit.createdAt) / (1000 * 60 * 60 * 24)
        );
        
        const expectedCompletions = Math.max(1, daysSinceCreation);
        const actualCompletions = habit.habitCompletionHistory.length;
        
        return Math.min(100, Math.round((actualCompletions / expectedCompletions) * 100));
    }
}

export default new AnalyticsService();
