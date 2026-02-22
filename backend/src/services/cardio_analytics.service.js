import DailyStepLog from '../models/DailyStepLog.js';

class CardioAnalyticsService {

    /**
     * Generates a 30-day step heatmap data array for GitHub-style calendar parsing.
     * Returns a map of YYYY-MM-DD -> total steps.
     */
    async get30DayHeatmap(userId) {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const dateStr = thirtyDaysAgo.toISOString().split('T')[0];

        // Query logs greater than or equal to 30 days ago
        const logs = await DailyStepLog.find({
            userId,
            date: { $gte: dateStr }
        }).select('date steps').lean();

        // Reduce into simple KV structure
        const heatmap = {};
        logs.forEach(log => heatmap[log.date] = log.steps);
        return heatmap;
    }

    /**
     * Aggregates step data into weekly sums for the last 'weeks' count.
     */
    async getWeeklyTrend(userId, weeks = 4) {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - (weeks * 7));
        const dateStr = cutoff.toISOString().split('T')[0];

        return await DailyStepLog.aggregate([
            {
                $match: { userId, date: { $gte: dateStr } }
            },
            {
                $group: {
                    // ISO Day of Week aggregation (1=Sunday, 7=Saturday typically depending on locale, we use ISO)
                    _id: { $toIsoDayOfWeek: { $dateFromString: { dateString: "$date" } } },
                    avgSteps: { $avg: "$steps" },
                    totalSteps: { $sum: "$steps" }
                }
            },
            { $sort: { "_id": 1 } }
        ]);
    }

    /**
     * Analyzes the past 30 days of hourly distributions to find
     * the user's most active hour (00-23).
     */
    async getPeakActivityHour(userId) {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const dateStr = thirtyDaysAgo.toISOString().split('T')[0];

        const logs = await DailyStepLog.find({
            userId,
            date: { $gte: dateStr }
        }).select('hourlyDistribution').lean();

        const hourlyAverages = new Array(24).fill(0);
        let totalLogsWithHours = 0;

        for (const log of logs) {
            if (!log.hourlyDistribution || log.hourlyDistribution.length === 0) continue;

            totalLogsWithHours++;
            for (const bucket of log.hourlyDistribution) {
                const h = parseInt(bucket.hour, 10);
                if (!isNaN(h) && h >= 0 && h <= 23) {
                    hourlyAverages[h] += bucket.steps;
                }
            }
        }

        if (totalLogsWithHours === 0) return null;

        // Find the max hour index
        let maxSteps = -1;
        let peakHour = 0;

        for (let i = 0; i < 24; i++) {
            hourlyAverages[i] = hourlyAverages[i] / totalLogsWithHours;
            if (hourlyAverages[i] > maxSteps) {
                maxSteps = hourlyAverages[i];
                peakHour = i;
            }
        }

        return peakHour; // Returns integer 0-23 representing highest average steps
    }

}

export default new CardioAnalyticsService();
