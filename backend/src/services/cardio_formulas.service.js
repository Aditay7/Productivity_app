/**
 * Cardio Formulas & AI Heuristics Service
 * Handles complex fitness math (BMR, METs) and predictive estimations.
 */

class CardioFormulasService {
    /**
     * Calculate Basal Metabolic Rate (BMR) using the Mifflin-St Jeor equation.
     * This represents the calories burned naturally in a day without exercise.
     * 
     * @param {number} weightKg 
     * @param {number} heightCm 
     * @param {number} age (Defaults to 25 if unknown)
     * @param {string} gender 'M' or 'F'
     * @returns {number} BMR daily calories
     */
    calculateBMR(weightKg, heightCm, age = 25, gender = 'M') {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
        return gender === 'M' ? base + 5 : base - 161;
    }

    /**
     * Calculate exact calories burned from an activity using METs (Metabolic Equivalent of Task).
     * 
     * MET values guide:
     * - Light walking (< 3mph): 2.5
     * - Moderate walking (3-4mph): 3.5
     * - Brisk walking/Jogging (5mph): 5.0
     * - Running (6mph): 9.8
     * 
     * Equation: Calories = MET * Weight(kg) * Time(hours)
     * 
     * @param {number} weightKg User's weight
     * @param {number} activeMinutes Total time spent active
     * @param {number} mets Metabolic Equivalent of Task
     * @returns {number} calories burned
     */
    calculateMETCalories(weightKg, activeMinutes, mets = 3.5) {
        if (!weightKg || !activeMinutes) return 0;
        const hours = activeMinutes / 60;
        return mets * weightKg * hours;
    }

    /**
     * Utility to estimate distance (km) and calories directly from raw steps
     * if speed/duration is unknown.
     * 
     * @param {number} steps
     * @param {number} heightCm Used to estimate stride length
     * @param {number} weightKg Used to estimate calorie expenditure
     */
    estimateFromSteps(steps, heightCm = 170, weightKg = 70) {
        if (!steps) return { distanceKm: 0, caloriesBurned: 0 };

        // Average stride length is roughly 41.4% of height for men, 41.3% for women. We'll use 41.4.
        const strideLengthMeters = (heightCm * 0.414) / 100;
        const distanceKm = (steps * strideLengthMeters) / 1000;

        // Rule of thumb: ~0.04 to 0.05 calories per step depending on weight
        // A more tailored rule: 0.57 cal per kg per km
        const caloriesBurned = 0.57 * weightKg * distanceKm;

        return {
            distanceKm: parseFloat(distanceKm.toFixed(2)),
            caloriesBurned: parseFloat(caloriesBurned.toFixed(1))
        };
    }

    /**
     * AI Predictive Heuristic: Predict tomorrow's step count without ML.
     * Uses Simple Moving Average of the last 7 days (60% weight) 
     * + Pattern matching the exact same day last week (40% weight).
     * 
     * @param {Array} historyLogs Array of {date, steps} ordered descending.
     * @returns {number} Predicted steps
     */
    predictTomorrowSteps(historyLogs) {
        if (!historyLogs || historyLogs.length === 0) return 8000; // Default baseline

        // Calculate Last 7 Days Average
        const recent7 = historyLogs.slice(0, 7);
        const sum7 = recent7.reduce((acc, log) => acc + log.steps, 0);
        const avg7 = sum7 / recent7.length;

        // Find the log from exactly 7 days ago to identify week-day patterns (e.g., "Lazy Sundays")
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const sameDayLastWeekStr = new Date(tomorrow.setDate(tomorrow.getDate() - 7)).toISOString().split('T')[0];

        const sameDayLastWeekLog = historyLogs.find(log => log.date.startsWith(sameDayLastWeekStr));

        if (sameDayLastWeekLog) {
            // 60% weight to recent trend momentum, 40% weight to strict weekly schedule
            const prediction = (avg7 * 0.6) + (sameDayLastWeekLog.steps * 0.4);
            return Math.round(prediction);
        }

        return Math.round(avg7); // Fallback to pure average if no week-over-week pattern data exists
    }
}

export default new CardioFormulasService();
