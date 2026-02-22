import mongoose from 'mongoose';

const playerSchema = new mongoose.Schema({
    level: { type: Number, default: 1 },
    totalXp: { type: Number, default: 0 },
    strength: { type: Number, default: 0 },
    intelligence: { type: Number, default: 0 },
    discipline: { type: Number, default: 0 },
    wealth: { type: Number, default: 0 },
    charisma: { type: Number, default: 0 },
    currentStreak: { type: Number, default: 0 },
    lastActivityDate: { type: Date, default: null },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },

    // Physical & Cardio Data
    heightCm: { type: Number, default: 170 },
    weightKg: { type: Number, default: 70 },
    gender: { type: String, enum: ['M', 'F', 'O'], default: 'M' },
    dailyStepGoal: { type: Number, default: 8000 },
    weeklyStepGoal: { type: Number, default: 56000 },
    isShadowMode: { type: Boolean, default: false },
    shadowModeActivatedAt: { type: Date, default: null },
    totalPenaltiesIncurred: { type: Number, default: 0 }
});

// Update the updatedAt timestamp before saving
playerSchema.pre('save', function (next) {
    this.updatedAt = new Date();
    next();
});

export const Player = mongoose.model('Player', playerSchema);
