import authService from '../services/auth.service.js';

export class AuthController {
    async register(req, res, next) {
        try {
            const result = await authService.register(req.body);
            res.status(201).json({
                success: true,
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    async login(req, res, next) {
        try {
            const result = await authService.login(req.body);
            res.json({
                success: true,
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    // A protected route to verify the token is returning the user cleanly
    async getMe(req, res, next) {
        try {
            res.json({
                success: true,
                data: req.user
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new AuthController();
