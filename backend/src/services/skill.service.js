import { Skill } from '../models/Skill.js';
import { Perk } from '../models/Perk.js';
import { AppError } from '../middleware/error.middleware.js';

export class SkillService {
    /**
     * Initialize default skills for a new player
     */
    async initializeSkills() {
        const defaultSkills = [
            {
                name: 'Coding',
                description: 'Programming and technical skills',
                icon: '💻',
                color: '#3498DB'
            },
            {
                name: 'Fitness',
                description: 'Physical health and exercise',
                icon: '💪',
                color: '#E74C3C'
            },
            {
                name: 'Communication',
                description: 'Social skills and networking',
                icon: '✨',
                color: '#E91E63'
            },
            {
                name: 'Discipline',
                description: 'Consistency and habit building',
                icon: '🎯',
                color: '#9B59B6'
            },
            {
                name: 'Learning',
                description: 'Knowledge acquisition and growth',
                icon: '🧠',
                color: '#F39C12'
            }
        ];

        const skills = await Skill.insertMany(defaultSkills);
        return skills;
    }

    /**
     * Get all skills
     */
    async getAllSkills() {
        return await Skill.find().sort({ name: 1 });
    }

    /**
     * Get skill by name
     */
    async getSkillByName(name) {
        const skill = await Skill.findOne({ name });

        if (!skill) {
            throw new AppError(404, `Skill ${name} not found`);
        }

        return skill;
    }

    /**
     * Add XP to a skill
     */
    async addSkillXP(skillName, xpAmount) {
        const skill = await this.getSkillByName(skillName);

        const oldLevel = skill.currentLevel;
        skill.totalXp += xpAmount;
        skill.currentXp = skill.totalXp - (Math.pow(skill.currentLevel, 2) * 50);

        await skill.save();

        const newLevel = skill.currentLevel;
        const leveledUp = newLevel > oldLevel;

        // Check for perk unlocks if leveled up
        let newPerks = [];
        if (leveledUp) {
            newPerks = await this.checkPerkUnlocks(skillName, newLevel);
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
    async checkPerkUnlocks(skillName, newLevel) {
        const perks = await Perk.find({
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
    async getAllPerks() {
        return await Perk.find().sort({ skillRequired: 1, levelRequired: 1 });
    }

    /**
     * Get perks by skill
     */
    async getPerksBySkill(skillName) {
        return await Perk.find({ skillRequired: skillName }).sort({ levelRequired: 1 });
    }

    /**
     * Get unlocked perks
     */
    async getUnlockedPerks() {
        return await Perk.find({ isUnlocked: true }).sort({ unlockedAt: -1 });
    }

    /**
     * Initialize default perks
     */
    async initializePerks() {
        const defaultPerks = [
            // Coding Perks
            { name: 'Code Sprint', description: 'Unlock 2x XP for coding quests on weekends', skillRequired: 'Coding', levelRequired: 5, icon: '⚡', featureKey: 'code_sprint' },
            { name: 'Deep Work Mode', description: 'Enable distraction-free coding sessions with Pomodoro timer', skillRequired: 'Coding', levelRequired: 10, icon: '🧘', featureKey: 'deep_work_mode' },
            { name: 'Mentor Mode', description: 'Unlock ability to create coding challenges for others', skillRequired: 'Coding', levelRequired: 15, icon: '👨‍🏫', featureKey: 'mentor_mode' },

            // Fitness Perks
            { name: 'Iron Will', description: 'Unlock streak protection (1 missed day won\'t break streak)', skillRequired: 'Fitness', levelRequired: 5, icon: '🛡️', featureKey: 'iron_will' },
            { name: 'Beast Mode', description: 'Unlock 2x difficulty quests with 3x rewards', skillRequired: 'Fitness', levelRequired: 10, icon: '🦁', featureKey: 'beast_mode' },
            { name: 'Recovery Master', description: 'Unlock rest day scheduling without penalty', skillRequired: 'Fitness', levelRequired: 15, icon: '😴', featureKey: 'recovery_master' },

            // Communication Perks
            { name: 'Networker', description: 'Unlock social quest templates', skillRequired: 'Communication', levelRequired: 5, icon: '🤝', featureKey: 'networker' },
            { name: 'Influencer', description: 'Unlock quest sharing and leaderboards', skillRequired: 'Communication', levelRequired: 10, icon: '📢', featureKey: 'influencer' },
            { name: 'Mentor', description: 'Unlock ability to guide other players', skillRequired: 'Communication', levelRequired: 15, icon: '🌟', featureKey: 'mentor' },

            // Discipline Perks
            { name: 'Hard Mode', description: 'Unlock penalty system for failed quests', skillRequired: 'Discipline', levelRequired: 5, icon: '⚔️', featureKey: 'hard_mode' },
            { name: 'Consistency King', description: 'Unlock weekly quest chains with bonus rewards', skillRequired: 'Discipline', levelRequired: 10, icon: '👑', featureKey: 'consistency_king' },
            { name: 'Shadow Mode', description: 'Unlock stealth mode (hidden from leaderboards)', skillRequired: 'Discipline', levelRequired: 15, icon: '🥷', featureKey: 'shadow_mode' },

            // Learning Perks
            { name: 'Quick Learner', description: 'Unlock XP bonus for completing quests early', skillRequired: 'Learning', levelRequired: 5, icon: '⏱️', featureKey: 'quick_learner' },
            { name: 'Knowledge Base', description: 'Unlock quest notes and reflection journal', skillRequired: 'Learning', levelRequired: 10, icon: '📚', featureKey: 'knowledge_base' },
            { name: 'Master Teacher', description: 'Unlock ability to create custom quest templates', skillRequired: 'Learning', levelRequired: 15, icon: '🎓', featureKey: 'master_teacher' }
        ];

        const perks = await Perk.insertMany(defaultPerks);
        return perks;
    }
}

export default new SkillService();
