import mongoose from 'mongoose';

const skillSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: {
        type: String,
        required: true,
        enum: ['Coding', 'Fitness', 'Communication', 'Discipline', 'Learning']
    },
    description: { type: String, required: true },
    icon: { type: String, required: true },
    color: { type: String, required: true }, // Hex color
    currentXp: { type: Number, default: 0 },
    currentLevel: { type: Number, default: 1 },
    totalXp: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

// Calculate level from XP
skillSchema.methods.calculateLevel = function () {
    // Formula: level^2 * 50 = XP required
    let level = 1;
    let xpRequired = 0;

    while (xpRequired <= this.totalXp) {
        level++;
        xpRequired = Math.pow(level, 2) * 50;
    }

    return level - 1;
};

// Calculate XP needed for next level
skillSchema.methods.xpToNextLevel = function () {
    const nextLevel = this.currentLevel + 1;
    const xpForNextLevel = Math.pow(nextLevel, 2) * 50;
    return xpForNextLevel - this.totalXp;
};

// Update level when XP changes
skillSchema.pre('save', function (next) {
    this.currentLevel = this.calculateLevel();
    this.updatedAt = new Date();
    next();
});

export const Skill = mongoose.model('Skill', skillSchema);
