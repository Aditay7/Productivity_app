import mongoose from 'mongoose';

const hourlyDistributionSchema = new mongoose.Schema({
  hour: {
    type: String, // '00' to '23'
    required: true,
    match: /^(0[0-9]|1[0-9]|2[0-3])$/
  },
  steps: {
    type: Number,
    default: 0
  }
}, { _id: false });

const dailyStepLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  date: {
    type: String, // Format: YYYY-MM-DD
    required: true
  },
  steps: {
    type: Number,
    default: 0,
    min: 0
  },
  caloriesBurned: {
    type: Number,
    default: 0,
    min: 0
  },
  distanceKm: {
    type: Number,
    default: 0,
    min: 0
  },
  activeMinutes: {
    type: Number,
    default: 0,
    min: 0
  },
  hourlyDistribution: [hourlyDistributionSchema], // Used for peak time analytics
  isGoalReached: {
    type: Boolean,
    default: false
  },
  goalAtTime: {
    type: Number,
    default: 10000 // Falls back to default if not specific
  },
  lastSyncedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound index to optimize querying a user's date ranges quickly
dailyStepLogSchema.index({ userId: 1, date: -1 }, { unique: true });

const DailyStepLog = mongoose.model('DailyStepLog', dailyStepLogSchema);

export default DailyStepLog;
