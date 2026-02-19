import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Player } from '../models/Player.js';
import { Achievement } from '../models/Achievement.js';

dotenv.config();

async function seed() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Clear existing data
        await Player.deleteMany({});
        await Achievement.deleteMany({});
        console.log('🗑️  Cleared existing data');

        // Create initial player
        const player = await Player.create({
            level: 1,
            totalXp: 0,
            strength: 0,
            intelligence: 0,
            discipline: 0,
            wealth: 0,
            charisma: 0,
            currentStreak: 0,
        });
        console.log('✅ Created player:', player._id);

        // Create achievements
        const achievements = [
            {
                key: 'first_quest',
                title: 'First Steps',
                description: 'Complete your first quest',
                icon: '🎯',
                unlockCondition: 'Complete 1 quest',
                category: 'quest',
            },
            {
                key: 'streak_7',
                title: 'Week Warrior',
                description: 'Maintain a 7-day streak',
                icon: '🔥',
                unlockCondition: '7-day streak',
                category: 'streak',
            },
            {
                key: 'streak_30',
                title: 'Month Master',
                description: 'Maintain a 30-day streak',
                icon: '⚡',
                unlockCondition: '30-day streak',
                category: 'streak',
            },
            {
                key: 'streak_100',
                title: 'Century Club',
                description: 'Maintain a 100-day streak',
                icon: '💎',
                unlockCondition: '100-day streak',
                category: 'streak',
            },
            {
                key: 'xp_1k',
                title: 'Novice Adventurer',
                description: 'Earn 1,000 total XP',
                icon: '⭐',
                unlockCondition: '1,000 XP',
                category: 'xp',
            },
            {
                key: 'xp_10k',
                title: 'Expert Hero',
                description: 'Earn 10,000 total XP',
                icon: '🌟',
                unlockCondition: '10,000 XP',
                category: 'xp',
            },
            {
                key: 'xp_100k',
                title: 'Legendary Champion',
                description: 'Earn 100,000 total XP',
                icon: '👑',
                unlockCondition: '100,000 XP',
                category: 'xp',
            },
            {
                key: 'strength_100',
                title: 'Iron Will',
                description: 'Reach 100 Strength',
                icon: '💪',
                unlockCondition: 'Strength > 100',
                category: 'stat',
            },
            {
                key: 'intelligence_100',
                title: 'Genius Mind',
                description: 'Reach 100 Intelligence',
                icon: '🧠',
                unlockCondition: 'Intelligence > 100',
                category: 'stat',
            },
            {
                key: 'discipline_100',
                title: 'Unbreakable',
                description: 'Reach 100 Discipline',
                icon: '🎯',
                unlockCondition: 'Discipline > 100',
                category: 'stat',
            },
            {
                key: 'wealth_100',
                title: 'Money Magnet',
                description: 'Reach 100 Wealth',
                icon: '💰',
                unlockCondition: 'Wealth > 100',
                category: 'stat',
            },
            {
                key: 'charisma_100',
                title: 'Social Butterfly',
                description: 'Reach 100 Charisma',
                icon: '✨',
                unlockCondition: 'Charisma > 100',
                category: 'stat',
            },
            {
                key: 'quests_50',
                title: 'Quest Hunter',
                description: 'Complete 50 quests',
                icon: '🏆',
                unlockCondition: '50 quests completed',
                category: 'quest',
            },
            {
                key: 'balanced_build',
                title: 'Balanced Build',
                description: 'All stats above 50',
                icon: '⚖️',
                unlockCondition: 'All stats > 50',
                category: 'stat',
            },
        ];

        await Achievement.insertMany(achievements);
        console.log(`✅ Created ${achievements.length} achievements`);

        console.log('🎉 Seeding completed!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
}

seed();
