import mongoose from 'mongoose';

const questSessionSchema = new mongoose.Schema({
    questId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Quest',
        required: true
    },
    sessionStart: { type: Date, required: true },
    sessionEnd: { type: Date, default: null },
    durationMinutes: { type: Number, default: 0 },
    pauseCount: { type: Number, default: 0 },
    focusRating: { type: Number, min: 1, max: 5, default: null },
    notes: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

// Index for faster queries
questSessionSchema.index({ questId: 1, createdAt: -1 });

export const QuestSession = mongoose.model('QuestSession', questSessionSchema);
