import mongoose from 'mongoose';

const workoutSessionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    type: {
        type: String,
        enum: ['walk', 'run', 'cycle'],
        required: true
    },
    startTime: {
        type: Date,
        required: true
    },
    endTime: {
        type: Date,
        required: true
    },
    durationSeconds: {
        type: Number,
        required: true,
        min: 1
    },
    steps: {
        type: Number,
        default: 0
    },
    distanceKm: {
        type: Number,
        default: 0
    },
    caloriesBurned: {
        type: Number,
        default: 0
    },
    averagePaceKmH: {
        type: Number,
        default: 0
    },
    routeCoords: {
        type: [[Number]], // Array of [lat, lng] pairs for GPS path reconstruction
        default: []
    },
    isSynced: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Index to quickly pull a user's recent workouts for their dashboard or history
workoutSessionSchema.index({ userId: 1, startTime: -1 });

const WorkoutSession = mongoose.model('WorkoutSession', workoutSessionSchema);

export default WorkoutSession;
