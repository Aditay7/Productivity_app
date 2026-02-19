/**
 * Migration script to update existing quests with new time tracking fields
 * Run this once to migrate old data to the new schema
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Quest } from '../models/Quest.js';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/solo_leveling';

async function migrateQuests() {
    try {
        console.log('🔄 Connecting to MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        console.log('\n📊 Starting quest migration...');

        // Rename timeMinutes to timeEstimatedMinutes for all quests
        const renameResult = await Quest.updateMany(
            { timeMinutes: { $exists: true } },
            { $rename: { 'timeMinutes': 'timeEstimatedMinutes' } }
        );
        console.log(`✅ Renamed timeMinutes → timeEstimatedMinutes: ${renameResult.modifiedCount} quests`);

        // Set default timerState for quests without it
        const timerStateResult = await Quest.updateMany(
            { timerState: { $exists: false } },
            {
                $set: {
                    timerState: 'not_started',
                    pausedDuration: 0,
                    distractionCount: 0,
                    isOverdue: false
                }
            }
        );
        console.log(`✅ Set default timerState: ${timerStateResult.modifiedCount} quests`);

        // Mark completed quests as timer completed
        const completedResult = await Quest.updateMany(
            { isCompleted: true, timerState: 'not_started' },
            { $set: { timerState: 'completed' } }
        );
        console.log(`✅ Updated completed quests timerState: ${completedResult.modifiedCount} quests`);

        // Check for overdue quests
        const now = new Date();
        const overdueResult = await Quest.updateMany(
            {
                isCompleted: false,
                deadline: { $lt: now, $ne: null },
                isOverdue: false
            },
            { $set: { isOverdue: true } }
        );
        console.log(`✅ Marked overdue quests: ${overdueResult.modifiedCount} quests`);

        // Create indexes for better performance
        console.log('\n📇 Creating indexes...');
        await Quest.collection.createIndex({ timerState: 1 });
        await Quest.collection.createIndex({ deadline: 1 });
        await Quest.collection.createIndex({ isOverdue: 1 });
        console.log('✅ Indexes created');

        // Summary
        const totalQuests = await Quest.countDocuments();
        const runningTimers = await Quest.countDocuments({ timerState: 'running' });
        const overdueQuests = await Quest.countDocuments({ isOverdue: true });

        console.log('\n📈 Migration Summary:');
        console.log(`   Total quests: ${totalQuests}`);
        console.log(`   Running timers: ${runningTimers}`);
        console.log(`   Overdue quests: ${overdueQuests}`);
        console.log('\n✅ Migration completed successfully!');

    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    } finally {
        await mongoose.connection.close();
        console.log('\n🔌 Disconnected from MongoDB');
        process.exit(0);
    }
}

// Run migration
migrateQuests();
