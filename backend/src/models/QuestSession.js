import mongoose from 'mongoose';

const questSessionSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
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

// Transform _id to id when converting to JSON
questSessionSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

export const QuestSession = mongoose.model('QuestSession', questSessionSchema);
