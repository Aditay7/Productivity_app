import mongoose from 'mongoose';

const questSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, default: '' },
    statType: { type: String, required: true }, // Legacy field for backward compatibility
    skillCategory: { type: String, default: null }, // New field for skill tree system
    difficulty: { type: Number, required: true },

    // Time Tracking
    timeEstimatedMinutes: { type: Number, required: true }, // Renamed from timeMinutes
    timeActualMinutes: { type: Number, default: null }, // Actual time spent (rounded minutes)
    timeActualSeconds: { type: Number, default: null }, // Actual time spent (precise seconds)
    timeStarted: { type: Date, default: null }, // When timer started
    timePaused: { type: Date, default: null }, // When timer paused
    pausedDuration: { type: Number, default: 0 }, // Total paused time in ms
    timerState: {
        type: String,
        enum: ['not_started', 'running', 'paused', 'completed'],
        default: 'not_started'
    },

    // Deadline Management
    deadline: { type: Date, default: null },
    isOverdue: { type: Boolean, default: false },

    // Productivity Metrics
    accuracyScore: { type: Number, default: null }, // % accuracy (0-100)
    productivityScore: { type: Number, default: null }, // Overall score (0-100)
    focusRating: { type: Number, min: 1, max: 5, default: null }, // User-rated focus (1-5)
    distractionCount: { type: Number, default: 0 }, // Times paused

    xpReward: { type: Number, required: true },
    dateCreated: { type: Date, default: Date.now },
    dateCompleted: { type: Date, default: null },
    completionTimeOfDay: { type: Number, default: null }, // Hour (0-23) when completed
    isCompleted: { type: Boolean, default: false },
    streakAtCompletion: { type: Number, default: 0 },
    templateId: { type: mongoose.Schema.Types.ObjectId, ref: 'QuestTemplate', default: null },
    isTemplateInstance: { type: Boolean, default: false }
});

export const Quest = mongoose.model('Quest', questSchema);
