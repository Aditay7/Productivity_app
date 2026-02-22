import mongoose from 'mongoose';

const perkSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true },
    description: { type: String, required: true },
    skillRequired: {
        type: String,
        required: true,
        enum: ['Coding', 'Fitness', 'Communication', 'Discipline', 'Learning']
    },
    levelRequired: { type: Number, required: true },
    icon: { type: String, required: true },
    featureKey: { type: String, required: true, unique: true },
    isUnlocked: { type: Boolean, default: false },
    unlockedAt: { type: Date, default: null },
    createdAt: { type: Date, default: Date.now }
});

export const Perk = mongoose.model('Perk', perkSchema);
