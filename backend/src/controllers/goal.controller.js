import goalService from '../services/goal.service.js';

export class GoalController {
    /**
     * GET /api/goals
     */
    async getAllGoals(req, res, next) {
        try {
            const filters = {
                type: req.query.type,
                statType: req.query.statType,
                isCompleted: req.query.isCompleted === 'true' ? true :
                    req.query.isCompleted === 'false' ? false : undefined
            };
            const goals = await goalService.getAllGoals(req.user.id, filters);
            res.json({
                success: true,
                data: goals,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/goals/active
     */
    async getActiveGoals(req, res, next) {
        try {
            const goals = await goalService.getActiveGoals(req.user.id);
            res.json({
                success: true,
                data: goals,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/goals/:id
     */
    async getGoalById(req, res, next) {
        try {
            const goal = await goalService.getGoalById(req.user.id, req.params.id);
            res.json({
                success: true,
                data: goal,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/goals
     */
    async createGoal(req, res, next) {
        try {
            const goal = await goalService.createGoal(req.user.id, req.body);
            res.status(201).json({
                success: true,
                data: goal,
                message: 'Goal created successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * PUT /api/goals/:id
     */
    async updateGoal(req, res, next) {
        try {
            const goal = await goalService.updateGoal(req.user.id, req.params.id, req.body);
            res.json({
                success: true,
                data: goal,
                message: 'Goal updated successfully',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/goals/:id/progress
     */
    async updateProgress(req, res, next) {
        try {
            const { value } = req.body;
            const goal = await goalService.updateGoalProgress(req.user.id, req.params.id, value);
            res.json({
                success: true,
                data: goal,
                message: 'Goal progress updated',
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * DELETE /api/goals/:id
     */
    async deleteGoal(req, res, next) {
        try {
            await goalService.deleteGoal(req.user.id, req.params.id);
            res.json({
                success: true,
                message: 'Goal deleted successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new GoalController();
