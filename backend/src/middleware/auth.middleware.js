import jwt from 'jsonwebtoken';
import { AppError } from './error.middleware.js';

export const protect = async (req, res, next) => {
    try {
        let token;

        // Check for Bearer token
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return next(new AppError(401, 'You are not logged in! Please log in to get access.'));
        }

        // Verify token
        // Use a fallback secret if .env is missing for some reason
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'solo_leveling_super_secret_key_123');

        // Attach userId to request object for downstream controllers and services
        req.user = { id: decoded.id };
        next();
    } catch (err) {
        return next(new AppError(401, 'Invalid token or token has expired. Please log in again.'));
    }
};
