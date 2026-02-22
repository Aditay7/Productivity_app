import { Quest } from '../models/Quest.js';
import { QuestTemplate } from '../models/QuestTemplate.js';
import { AppError } from '../middleware/error.middleware.js';
import playerService from './player.service.js';
import goalService from './goal.service.js';

export class QuestService {
    /**
     * Create a new quest
     */
    async createQuest(userId, data) {
        const quest = await Quest.create({ ...data, userId });
        return quest;
    }

    /**
     * Get all quests with optional filters
     */
    async getAllQuests(userId, filters = {}) {
        // Lazy generation: Check for recurring quests due today
        await this._generateDailyQuestsFromTemplates(userId);

        const query = { userId };

        if (filters.isCompleted !== undefined) {
            query.isCompleted = filters.isCompleted;
        }

        if (filters.statType) {
            query.statType = filters.statType;
        }

        if (filters.templateId) {
            query.templateId = filters.templateId;
        }

        if (filters.startDate || filters.endDate) {
            query.dateCreated = {};
            if (filters.startDate) {
                query.dateCreated.$gte = new Date(filters.startDate);
            }
            if (filters.endDate) {
                query.dateCreated.$lte = new Date(filters.endDate);
            }
        }

        return await Quest.find(query)
            .sort({ dateCreated: -1 });
    }

    /**
     * Get quest by ID
     */
    async getQuestById(userId, id) {
        const quest = await Quest.findOne({ _id: id, userId });

        if (!quest) {
            throw new AppError(404, 'Quest not found or unauthorized');
        }

        return quest;
    }

    /**
     * Get today's quests
     */
    async getTodayQuests(userId) {
        // Lazy generation: Check for recurring quests due today
        await this._generateDailyQuestsFromTemplates(userId);

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        return await Quest.find({
            userId,
            dateCreated: {
                $gte: today,
                $lt: tomorrow,
            },
        })
            .sort({ dateCreated: -1 });
    }

    /**
     * Update quest
     */
    async updateQuest(userId, id, data) {
        const quest = await Quest.findOneAndUpdate({ _id: id, userId }, data, { new: true }).populate('templateId');

        if (!quest) {
            throw new AppError(404, 'Quest not found or unauthorized');
        }

        return quest;
    }

    /**
     * Complete a quest
     */
    async completeQuest(userId, id) {
        const quest = await this.getQuestById(userId, id);

        if (quest.isCompleted) {
            // Idempotency: If already completed, return success
            return {
                quest: quest,
                skillResult: null
            };
        }

        // Get current player for streak
        const player = await playerService.getPlayer(userId);

        // Update quest
        quest.isCompleted = true;
        quest.dateCompleted = new Date();
        quest.completionTimeOfDay = new Date().getHours(); // Store hour of completion
        quest.streakAtCompletion = player.currentStreak;
        await quest.save();

        // Calculate XP with productivity bonus/penalty
        let finalXP = quest.xpReward;
        let xpModifier = 1.0; // Default: no change
        let performanceMessage = null;

        if (quest.productivityScore !== null && quest.productivityScore !== undefined) {
            // Productivity-based XP multiplier:
            // 90-100: +30% XP bonus
            // 80-89: +20% XP bonus
            // 70-79: +10% XP bonus
            // 60-69: Normal XP (no change)
            // 50-59: -10% XP penalty
            // 40-49: -20% XP penalty
            // < 40: -30% XP penalty

            if (quest.productivityScore >= 90) {
                xpModifier = 1.30;
                performanceMessage = 'Excellent performance! +30% XP bonus';
            } else if (quest.productivityScore >= 80) {
                xpModifier = 1.20;
                performanceMessage = 'Great performance! +20% XP bonus';
            } else if (quest.productivityScore >= 70) {
                xpModifier = 1.10;
                performanceMessage = 'Good performance! +10% XP bonus';
            } else if (quest.productivityScore >= 60) {
                xpModifier = 1.0;
                performanceMessage = 'Decent performance';
            } else if (quest.productivityScore >= 50) {
                xpModifier = 0.90;
                performanceMessage = 'Below target: -10% XP';
            } else if (quest.productivityScore >= 40) {
                xpModifier = 0.80;
                performanceMessage = 'Poor focus: -20% XP';
            } else {
                xpModifier = 0.70;
                performanceMessage = 'Needs improvement: -30% XP';
            }

            finalXP = Math.round(quest.xpReward * xpModifier);
        }

        // Add XP to player
        await playerService.addXP(userId, finalXP, quest.statType);

        // ── Auto-sync goal progress (fire-and-forget) ─────────────────
        // Goals track quest counts / XP / streaks. Refresh them now so
        // the user sees progress update immediately after completion.
        try {
            const updatedPlayer = await playerService.getPlayer(userId);
            const completedCount = await this.getCompletedCount(userId);
            await goalService.checkGoalsProgress(
                userId,
                {
                    totalXp: updatedPlayer.totalXp ?? 0,
                    currentStreak: updatedPlayer.currentStreak ?? 0,
                    // Top-level stat fields on the Player model
                    strength: updatedPlayer.strength ?? 0,
                    intelligence: updatedPlayer.intelligence ?? 0,
                    discipline: updatedPlayer.discipline ?? 0,
                    wealth: updatedPlayer.wealth ?? 0,
                    charisma: updatedPlayer.charisma ?? 0,
                },
                { completedCount }
            );
        } catch (goalErr) {
            // Never let goal sync failure break quest completion
            console.warn('[Goals] Auto-sync failed (non-fatal):', goalErr.message);
        }

        let skillResult = null;
        if (quest.skillCategory) {
            const skillService = (await import('./skill.service.js')).default;
            skillResult = await skillService.addSkillXP(userId, quest.skillCategory, finalXP);
        }

        return {
            quest: quest,
            skillResult, // Contains: { skill, leveledUp, oldLevel, newLevel, newPerks }
            xpEarned: finalXP,
            xpModifier: xpModifier,
            performanceMessage: performanceMessage
        };
    }

    /**
     * Delete quest
     */
    async deleteQuest(userId, id) {
        const quest = await Quest.findOneAndDelete({ _id: id, userId });

        if (!quest) {
            throw new AppError(404, 'Quest not found or unauthorized');
        }
    }

    /**
     * Get completed quests count
     */
    async getCompletedCount(userId) {
        return await Quest.countDocuments({ userId, isCompleted: true });
    }

    /**
     * Start quest timer
     */
    async startQuestTimer(userId, id) {
        const quest = await this.getQuestById(userId, id);

        if (quest.isCompleted) {
            throw new AppError(400, 'Cannot start timer on completed quest');
        }

        if (quest.timerState === 'running') {
            throw new AppError(400, 'Timer is already running');
        }

        if (quest.timerState === 'completed') {
            throw new AppError(400, 'Timer has already been stopped for this quest');
        }

        quest.timerState = 'running';
        quest.timeStarted = new Date();
        quest.timePaused = null;
        quest.pausedDuration = 0;
        quest.distractionCount = 0;

        await quest.save();
        return quest;
    }

    /**
     * Pause quest timer
     */
    async pauseQuestTimer(userId, id) {
        const quest = await this.getQuestById(userId, id);

        if (quest.timerState !== 'running') {
            throw new AppError(400, 'Timer is not running');
        }

        quest.timerState = 'paused';
        quest.timePaused = new Date();
        quest.distractionCount += 1;

        await quest.save();
        return quest;
    }

    /**
     * Resume quest timer
     */
    async resumeQuestTimer(userId, id) {
        const quest = await this.getQuestById(userId, id);

        if (quest.timerState !== 'paused') {
            throw new AppError(400, 'Timer is not paused');
        }

        // Calculate paused duration
        if (quest.timePaused) {
            const pausedMs = new Date() - quest.timePaused;
            quest.pausedDuration += pausedMs;
        }

        quest.timerState = 'running';
        quest.timePaused = null;

        await quest.save();
        return quest;
    }

    /**
     * Stop quest timer (without completing)
     */
    async stopQuestTimer(userId, id, focusRating = null) {
        const quest = await this.getQuestById(userId, id);

        if (quest.timerState === 'not_started' || quest.timerState === 'completed') {
            throw new AppError(400, 'Timer is not active');
        }

        // Calculate actual time
        const now = new Date();
        let totalMs = now - quest.timeStarted;

        // Subtract paused duration
        if (quest.timerState === 'paused' && quest.timePaused) {
            totalMs -= (now - quest.timePaused);
        }
        totalMs -= quest.pausedDuration;

        quest.timeActualMinutes = Math.round(totalMs / 60000); // Convert to minutes
        quest.timeActualSeconds = Math.round(totalMs / 1000);  // Precise seconds
        quest.timerState = 'completed';
        quest.focusRating = focusRating;

        // Calculate productivity scores
        const scores = this.calculateProductivityScore(
            quest.timeEstimatedMinutes,
            quest.timeActualMinutes,
            focusRating,
            quest.distractionCount
        );
        quest.accuracyScore = scores.accuracyScore;
        quest.productivityScore = scores.productivityScore;

        await quest.save();
        return quest;
    }

    /**
     * Complete quest with timer data
     */
    async completeQuestWithTimer(userId, id, focusRating = null) {
        // First stop the timer if running
        const quest = await this.getQuestById(userId, id);

        if (quest.timerState === 'running' || quest.timerState === 'paused') {
            await this.stopQuestTimer(userId, id, focusRating);
        }

        // Then complete the quest
        return await this.completeQuest(userId, id);
    }

    /**
     * Calculate productivity score
     */
    calculateProductivityScore(estimatedMinutes, actualMinutes, focusRating = null, distractionCount = 0) {
        // Accuracy Score (0-100): How close actual time was to estimated
        let accuracyScore = 0;
        if (actualMinutes > 0) {
            const ratio = Math.min(estimatedMinutes, actualMinutes) / Math.max(estimatedMinutes, actualMinutes);
            accuracyScore = Math.round(ratio * 100);
        }

        // Productivity Score (0-100): Weighted combination of factors
        let productivityScore = accuracyScore * 0.4; // 40% weight on accuracy

        // Focus rating (1-5) contributes 40%
        if (focusRating) {
            productivityScore += (focusRating / 5) * 40;
        } else {
            productivityScore += 20; // Neutral if not rated
        }

        // Distraction penalty (20% weight)
        const distractionPenalty = Math.min(distractionCount * 5, 20); // Max 20% penalty
        productivityScore += (20 - distractionPenalty);

        return {
            accuracyScore: Math.round(accuracyScore),
            productivityScore: Math.round(Math.max(0, Math.min(100, productivityScore)))
        };
    }

    /**
     * Check and mark overdue quests
     */
    async checkOverdueQuests(userId) {
        const now = new Date();

        const result = await Quest.updateMany(
            {
                userId,
                isCompleted: false,
                deadline: { $lt: now, $ne: null },
                isOverdue: false
            },
            {
                $set: { isOverdue: true }
            }
        );

        return result.modifiedCount;
    }

    /**
     * Get overdue quests
     */
    async getOverdueQuests(userId) {
        return await Quest.find({
            userId,
            isCompleted: false,
            isOverdue: true
        }).sort({ deadline: 1 });
    }

    /**
     * Get quests due soon (within next 24 hours)
     */
    async getDueSoonQuests(userId) {
        const now = new Date();
        const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

        return await Quest.find({
            userId,
            isCompleted: false,
            deadline: { $gte: now, $lte: tomorrow }
        }).sort({ deadline: 1 });
    }

    /**
     * Internal: Generate daily quests from active templates
     */
    async _generateDailyQuestsFromTemplates(userId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Find active templates
        const templates = await QuestTemplate.find({ userId, isActive: true });

        let dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, etc.
        if (dayOfWeek === 0) dayOfWeek = 7; // Convert Sunday to 7 to match frontend (Mon=1...Sun=7)

        for (const template of templates) {
            // Check if already generated for today
            if (template.lastGeneratedDate) {
                const lastGen = new Date(template.lastGeneratedDate);
                lastGen.setHours(0, 0, 0, 0);
                if (lastGen.getTime() === today.getTime()) {
                    continue; // Already generated today
                }
            }

            let shouldGenerate = false;

            if (template.recurrenceType === 'daily') {
                shouldGenerate = true;
            } else if (template.recurrenceType === 'specific_days' || template.recurrenceType === 'weekly') {
                // Check if today matches specified weekdays
                // Handle both 1-7 (ISO) and 0-6 (JS) formats if necessary, 
                // but usually sticking to one standard is best.
                // Assuming stored weekdays matches JS getDay() (0-6)
                if (template.weekdays && template.weekdays.includes(dayOfWeek)) {
                    shouldGenerate = true;
                }
            } else if (template.recurrenceType === 'interval') {
                // Check if enough days have passed
                if (template.lastGeneratedDate) {
                    const lastGen = new Date(template.lastGeneratedDate);
                    lastGen.setHours(0, 0, 0, 0);
                    const diffDays = Math.floor((today - lastGen) / (1000 * 60 * 60 * 24));
                    if (diffDays >= template.customDays) {
                        shouldGenerate = true;
                    }
                } else {
                    shouldGenerate = true; // First time
                }
            }

            if (shouldGenerate) {
                // Create quest from template
                await Quest.create({
                    userId,
                    title: template.title,
                    description: template.description || '',
                    statType: template.statType,
                    difficulty: parseInt(template.difficulty) || 1, // Ensure number
                    timeEstimatedMinutes: template.timeMinutes,
                    xpReward: 10 * (parseInt(template.difficulty) || 1), // Simple calculation
                    dateCreated: new Date(),
                    templateId: template._id,
                    isTemplateInstance: true
                });

                // Update template
                template.lastGeneratedDate = new Date();
                await template.save();
            }
        }
    }
}

export default new QuestService();
