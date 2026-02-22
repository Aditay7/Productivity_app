import mongoose from 'mongoose';

const questTemplateSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    timeMinutes: { type: Number, required: true },
    difficulty: { type: String, required: true },
    statType: { type: String, required: true },
    recurrenceType: { type: String, required: true },
    weekdays: { type: [Number], default: null },
    customDays: { type: Number, default: null },
    createdAt: { type: Date, default: Date.now },
    isActive: { type: Boolean, default: true },
    lastGeneratedDate: { type: Date, default: null },
    isHabit: { type: Boolean, default: false },
    habitStreak: { type: Number, default: 0 },
    habitLastCompletedDate: { type: Date, default: null },
    habitCompletionHistory: [{ type: Date }] // Array of completion dates
});

// Transform _id to id when converting to JSON
questTemplateSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

export const QuestTemplate = mongoose.model('QuestTemplate', questTemplateSchema);
