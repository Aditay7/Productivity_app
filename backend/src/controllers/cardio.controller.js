import cardioAnalyticsService from '../services/cardio_analytics.service.js';
import DailyStepLog from '../models/DailyStepLog.js';
import WorkoutSession from '../models/WorkoutSession.js';

/**
 * @desc    Bulk sync local step logs to MongoDB
 * @route   POST /api/cardio/daily-logs/sync
 * @access  Public (Single Player System)
 */
export const syncDailyLogs = async (req, res) => {
    try {
        const userId = req.user.id;
        const { logs } = req.body; // Array of { date, steps, caloriesBurned, distanceKm, activeMinutes, hourlyDistribution }

        if (!Array.isArray(logs)) {
            return res.status(400).json({ message: 'Payload must contain an array of logs.' });
        }

        const bulkOps = logs.map(log => {
            // Create update operation using $max to avoid older delayed payloads overriding newer local data
            return {
                updateOne: {
                    filter: { userId, date: log.date },
                    update: {
                        $max: {
                            steps: log.steps || 0,
                            caloriesBurned: log.caloriesBurned || 0,
                            distanceKm: log.distanceKm || 0,
                            activeMinutes: log.activeMinutes || 0
                        },
                        $set: {
                            hourlyDistribution: log.hourlyDistribution || [],
                            lastSyncedAt: new Date()
                        }
                    },
                    upsert: true
                }
            };
        });

        if (bulkOps.length > 0) {
            await DailyStepLog.bulkWrite(bulkOps);
        }

        res.status(200).json({ message: 'Sync successful', syncedCount: logs.length });
    } catch (error) {
        console.error('Error syncing cardio logs:', error);
        res.status(500).json({ message: 'Failed to sync logs' });
    }
};

/**
 * @desc    Get Cardio Analytics Summary
 * @route   GET /api/cardio/analytics/summary
 * @access  Public (Single Player System)
 */
export const getAnalyticsSummary = async (req, res) => {
    try {
        const userId = req.user.id;

        // Run heavy aggregations in parallel
        const [heatmap, weeklyTrend, peakHour] = await Promise.all([
            cardioAnalyticsService.get30DayHeatmap(userId),
            cardioAnalyticsService.getWeeklyTrend(userId, 4), // Last 4 weeks
            cardioAnalyticsService.getPeakActivityHour(userId)
        ]);

        res.status(200).json({
            heatmap,
            weeklyTrend,
            peakHour, // E.g., 18 for 6:00 PM
            message: 'Analytics retrieved successfully'
        });
    } catch (error) {
        console.error('Error fetching cardio analytics:', error);
        res.status(500).json({ message: 'Server error fetching analytics' });
    }
};

/**
 * @desc    Save a completed workout session
 * @route   POST /api/cardio/workouts
 * @access  Public (Single Player System)
 */
export const saveWorkout = async (req, res) => {
    try {
        const userId = req.user.id;

        const { type, startTime, endTime, durationSeconds, steps, distanceKm, caloriesBurned, averagePaceKmH, routeCoords } = req.body;

        const session = await WorkoutSession.create({
            userId,
            type,
            startTime,
            endTime,
            durationSeconds,
            steps,
            distanceKm,
            caloriesBurned,
            averagePaceKmH,
            routeCoords
        });

        res.status(201).json(session);
    } catch (error) {
        console.error('Error saving workout session:', error);
        res.status(500).json({ message: 'Failed to save workout' });
    }
};
