/**
 * Calculate player level from total XP
 * Formula: level = floor(sqrt(totalXP / 100))
 */
export function calculateLevel(totalXP) {
    return Math.floor(Math.sqrt(totalXP / 100));
}

/**
 * Calculate XP reward based on difficulty and time
 */
export function calculateXPReward(difficulty, timeMinutes) {
    const baseXP = difficulty * 10;
    const timeBonus = Math.floor(timeMinutes / 10);
    return baseXP + timeBonus;
}

/**
 * Calculate streak based on last activity date
 */
export function calculateStreak(lastActivityDate, currentStreak) {
    if (!lastActivityDate) {
        return 1;
    }

    const now = new Date();
    const lastDate = new Date(
        lastActivityDate.getFullYear(),
        lastActivityDate.getMonth(),
        lastActivityDate.getDate()
    );
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const diffDays = Math.floor(
        (today.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (diffDays === 0) {
        // Same day, keep streak
        return currentStreak;
    } else if (diffDays === 1) {
        // Next day, increment streak
        return currentStreak + 1;
    } else {
        // Streak broken, reset to 1
        return 1;
    }
}
