import { Skill } from '../models/Skill.js';
import { Perk } from '../models/Perk.js';
import { AppError } from '../middleware/error.middleware.js';

export class SkillService {
    /**
     * Initialize default skills for a new player
     */
    async initializeSkills(userId) {
        const defaultSkills = [
            { name: 'Coding', description: 'Programming and technical skills', icon: '💻', color: '#3498DB' },
            { name: 'Fitness', description: 'Physical health and exercise', icon: '💪', color: '#E74C3C' },
            { name: 'Communication', description: 'Social skills and networking', icon: '✨', color: '#E91E63' },
            { name: 'Discipline', description: 'Consistency and habit building', icon: '🎯', color: '#9B59B6' },
            { name: 'Learning', description: 'Knowledge acquisition and growth', icon: '🧠', color: '#F39C12' }
        ];

        const skillsToInsert = defaultSkills.map(s => ({ ...s, userId }));
        return await Skill.insertMany(skillsToInsert);
    }

    /**
     * Get all skills
     */
    async getAllSkills(userId) {
        return await Skill.find({ userId }).sort({ name: 1 });
    }

    /**
     * Get skill by name
     */
    async getSkillByName(userId, name) {
        const skill = await Skill.findOne({ userId, name });

        if (!skill) {
            throw new AppError(404, `Skill ${name} not found`);
        }

        return skill;
    }

    /**
     * Add XP to a skill
     */
    async addSkillXP(userId, skillName, xpAmount) {
        const skill = await this.getSkillByName(userId, skillName);

        const oldLevel = skill.currentLevel;
        skill.totalXp += xpAmount;
        skill.currentXp = skill.totalXp - (Math.pow(skill.currentLevel, 2) * 50);

        await skill.save();

        const newLevel = skill.currentLevel;
        const leveledUp = newLevel > oldLevel;

        let newPerks = [];
        if (leveledUp) {
            newPerks = await this.checkPerkUnlocks(userId, skillName, newLevel);
        }

        return {
            skill,
            leveledUp,
            oldLevel,
            newLevel,
            newPerks
        };
    }

    /**
     * Check and unlock perks when leveling up
     */
    async checkPerkUnlocks(userId, skillName, newLevel) {
        const perks = await Perk.find({
            userId,
            skillRequired: skillName,
            levelRequired: { $lte: newLevel },
            isUnlocked: false
        });

        const unlockedPerks = [];

        for (const perk of perks) {
            perk.isUnlocked = true;
            perk.unlockedAt = new Date();
            await perk.save();
            unlockedPerks.push(perk);
        }

        return unlockedPerks;
    }

    /**
     * Get all perks
     */
    async getAllPerks(userId) {
        return await Perk.find({ userId }).sort({ skillRequired: 1, levelRequired: 1 });
    }

    /**
     * Get perks by skill
     */
    async getPerksBySkill(userId, skillName) {
        return await Perk.find({ userId, skillRequired: skillName }).sort({ levelRequired: 1 });
    }

    /**
     * Get unlocked perks
     */
    async getUnlockedPerks(userId) {
        return await Perk.find({ userId, isUnlocked: true }).sort({ unlockedAt: -1 });
    }

    /**
     * Initialize default perks
     */
    async initializePerks(userId) {
        const defaultPerks = [
            // Coding Perks
            { name: 'Code Sprint', description: 'Unlock 2x XP for coding quests', skillRequired: 'Coding', levelRequired: 5, icon: '⚡', featureKey: 'code_sprint' },
            { name: 'Deep Work Mode', description: 'Enable distraction-free coding', skillRequired: 'Coding', levelRequired: 10, icon: '🧘', featureKey: 'deep_work_mode' },
            { name: 'Mentor Mode', description: 'Create coding challenges for others', skillRequired: 'Coding', levelRequired: 15, icon: '👨‍🏫', featureKey: 'mentor_mode' },

            // Fitness Perks
            { name: 'Iron Will', description: 'Unlock streak protection', skillRequired: 'Fitness', levelRequired: 5, icon: '🛡️', featureKey: 'iron_will' },
            { name: 'Beast Mode', description: '2x difficulty with 3x rewards', skillRequired: 'Fitness', levelRequired: 10, icon: '🦁', featureKey: 'beast_mode' },
            { name: 'Recovery Master', description: 'Rest day without penalty', skillRequired: 'Fitness', levelRequired: 15, icon: '😴', featureKey: 'recovery_master' },

            // Communication Perks
            { name: 'Networker', description: 'Social quest templates', skillRequired: 'Communication', levelRequired: 5, icon: '🤝', featureKey: 'networker' },
            { name: 'Influencer', description: 'Quest sharing leaderboards', skillRequired: 'Communication', levelRequired: 10, icon: '📢', featureKey: 'influencer' },
            { name: 'Mentor', description: 'Guide other players', skillRequired: 'Communication', levelRequired: 15, icon: '🌟', featureKey: 'mentor' },

            // Discipline Perks
            { name: 'Hard Mode', description: 'Penalty system for failed quests', skillRequired: 'Discipline', levelRequired: 5, icon: '⚔️', featureKey: 'hard_mode' },
            { name: 'Consistency King', description: 'Weekly quest chains bonus rewards', skillRequired: 'Discipline', levelRequired: 10, icon: '👑', featureKey: 'consistency_king' },
            { name: 'Shadow Mode', description: 'Hidden from leaderboards', skillRequired: 'Discipline', levelRequired: 15, icon: '🥷', featureKey: 'shadow_mode' },

            // Learning Perks
            { name: 'Quick Learner', description: 'XP bonus completing quests early', skillRequired: 'Learning', levelRequired: 5, icon: '⏱️', featureKey: 'quick_learner' },
            { name: 'Knowledge Base', description: 'Quest notes and reflection journal', skillRequired: 'Learning', levelRequired: 10, icon: '📚', featureKey: 'knowledge_base' },
            { name: 'Master Teacher', description: 'Create custom quest templates', skillRequired: 'Learning', levelRequired: 15, icon: '🎓', featureKey: 'master_teacher' }
        ];

        const perksToInsert = defaultPerks.map(p => ({ ...p, userId }));
        return await Perk.insertMany(perksToInsert);
    }
}

export default new SkillService();
