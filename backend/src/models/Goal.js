import mongoose from 'mongoose';

const goalSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, default: '' },
    type: { type: String, enum: ['monthly', 'yearly', 'custom'], required: true },
    statType: { type: String, required: true }, // Which stat this goal is for
    targetValue: { type: Number, required: true }, // Target XP or quest count
    currentValue: { type: Number, default: 0 },
    unit: { type: String, enum: ['xp', 'quests', 'streak'], default: 'quests' },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    milestones: [{
        value: { type: Number, required: true },
        label: { type: String, required: true },
        reached: { type: Boolean, default: false },
        reachedAt: { type: Date }
    }],
    achievements: [{
        title: { type: String, required: true },
        description: { type: String, required: true },
        unlockedAt: { type: Date, default: Date.now },
        milestoneValue: { type: Number } // Which milestone value unlocked this
    }],
    isCompleted: { type: Boolean, default: false },
    completedAt: { type: Date },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

// Transform _id to id when converting to JSON
goalSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

export const Goal = mongoose.model('Goal', goalSchema);
