import authService from '../services/auth.service.js';
import { User } from '../models/User.js';

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

    // Protected route to verify the token and return the full user profile
    async getMe(req, res, next) {
        try {
            const user = await User.findById(req.user.id).select('-passwordHash');
            if (!user) {
                return res.status(404).json({ success: false, message: 'User not found' });
            }
            res.json({
                success: true,
                data: {
                    id: user._id.toString(),
                    username: user.username,
                    email: user.email
                }
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new AuthController();
