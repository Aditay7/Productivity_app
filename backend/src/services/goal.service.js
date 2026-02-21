import { Goal } from '../models/Goal.js';
import { Quest } from '../models/Quest.js';
import { AppError } from '../middleware/error.middleware.js';

export class GoalService {
    /**
     * Create a new goal
     */
    async createGoal(data) {
        return await Goal.create(data);
    }

    /**
     * Get all goals
     */
    async getAllGoals(filters = {}) {
        const query = {};

        if (filters.type) query.type = filters.type;
        if (filters.statType) query.statType = filters.statType;
        if (filters.isCompleted !== undefined) query.isCompleted = filters.isCompleted;

        return await Goal.find(query).sort({ createdAt: -1 });
    }

    /**
     * Get active goals (not completed, within date range)
     */
    async getActiveGoals() {
        const now = new Date();
        return await Goal.find({
            isCompleted: false,
            startDate: { $lte: now },
            endDate: { $gte: now }
        }).sort({ endDate: 1 });
    }

    /**
     * Get goal by ID
     */
    async getGoalById(id) {
        const goal = await Goal.findById(id);
        if (!goal) {
            throw new AppError(404, 'Goal not found');
        }
        return goal;
    }

    /**
     * Update goal
     */
    async updateGoal(id, data) {
        const goal = await Goal.findByIdAndUpdate(
            id,
            { ...data, updatedAt: new Date() },
            { new: true }
        );

        if (!goal) {
            throw new AppError(404, 'Goal not found');
        }

        return goal;
    }

    /**
     * Update goal progress
     */
    async updateGoalProgress(id, newValue) {
        const goal = await this.getGoalById(id);

        goal.currentValue = newValue;
        goal.updatedAt = new Date();

        // Check milestones and unlock achievements
        if (goal.milestones) {
            goal.milestones.forEach(milestone => {
                if (!milestone.reached && newValue >= milestone.value) {
                    milestone.reached = true;
                    milestone.reachedAt = new Date();

                    // Unlock achievement for this milestone
                    const achievement = {
                        title: `${milestone.label} Milestone Reached!`,
                        description: `You've reached ${milestone.value} ${goal.unit} for "${goal.title}"`,
                        unlockedAt: new Date(),
                        milestoneValue: milestone.value
                    };

                    if (!goal.achievements) goal.achievements = [];
                    goal.achievements.push(achievement);
                }
            });
        }

        // Check if goal completed and unlock final achievement
        if (newValue >= goal.targetValue && !goal.isCompleted) {
            goal.isCompleted = true;
            goal.completedAt = new Date();

            // Unlock completion achievement
            const completionAchievement = {
                title: `🏆 Goal Completed: ${goal.title}`,
                description: `Congratulations! You've completed your ${goal.type} goal!`,
                unlockedAt: new Date(),
                milestoneValue: goal.targetValue
            };

            if (!goal.achievements) goal.achievements = [];
            goal.achievements.push(completionAchievement);
        }

        await goal.save();
        return goal;
    }

    /**
     * Delete goal
     */
    async deleteGoal(id) {
        const goal = await Goal.findByIdAndDelete(id);
        if (!goal) {
            throw new AppError(404, 'Goal not found');
        }
    }

    /**
     * Get goal progress percentage
     */
    getProgress(goal) {
        if (!goal) return 0;
        return Math.min(100, Math.round((goal.currentValue / goal.targetValue) * 100));
    }

    /**
     * Check and update all active goals based on player/quest data
     */
    async checkGoalsProgress(playerData, _questData) {
        const activeGoals = await this.getActiveGoals();

        for (const goal of activeGoals) {
            let newValue = goal.currentValue;

            switch (goal.unit) {
                case 'xp':
                    if (goal.statType === 'total') {
                        newValue = playerData.totalXp ?? 0;
                    } else {
                        newValue = playerData[goal.statType] ?? 0;
                    }
                    break;

                case 'quests': {
                    // Count only completed quests matching this goal's statType AND completed after the goal started
                    const questQuery = {
                        isCompleted: true,
                    };

                    if (goal.startDate) {
                        questQuery.dateCompleted = { $gte: goal.startDate };
                    }

                    if (goal.statType && goal.statType !== 'total') {
                        questQuery.statType = goal.statType;
                    }
                    newValue = await Quest.countDocuments(questQuery);
                    break;
                }

                case 'streak':
                    newValue = playerData.currentStreak ?? 0;
                    break;
            }

            if (newValue !== goal.currentValue) {
                await this.updateGoalProgress(goal._id, newValue);
            }
        }
    }
}

export default new GoalService();
