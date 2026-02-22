import mongoose from 'mongoose';

const timerSessionSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    durationMinutes: { type: Number, required: true },
    status: { type: String, enum: ['active', 'completed', 'failed'], default: 'active' },
    rank: { type: String, enum: ['E', 'C', 'A', 'S'], required: true },
    xpEarned: { type: Number, default: 0 },
    startedAt: { type: Date, default: Date.now },
    endedAt: { type: Date }
});

// Transform _id to id when converting to JSON
timerSessionSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

export const TimerSession = mongoose.model('TimerSession', timerSessionSchema);
