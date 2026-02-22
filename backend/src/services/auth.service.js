import { User } from '../models/User.js';
import { Player } from '../models/Player.js';
import jwt from 'jsonwebtoken';
import { AppError } from '../middleware/error.middleware.js';

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET || 'solo_leveling_super_secret_key_123', {
        expiresIn: '30d',
    });
};

export class AuthService {
    async register(data) {
        const { username, email, password } = data;

        if (!username || !email || !password) {
            throw new AppError(400, 'Please provide all required fields');
        }

        const userExists = await User.findOne({ email });
        if (userExists) {
            throw new AppError(400, 'User already exists');
        }

        // Create the user
        const user = await User.create({
            username,
            email,
            passwordHash: password // The pre-save hook will hash this
        });

        // Initialize a new empty Player profile linked to this User
        await Player.create({
            userId: user._id
        });

        const token = generateToken(user._id);

        return {
            user: {
                id: user._id,
                username: user.username,
                email: user.email
            },
            token
        };
    }

    async login(data) {
        const { email, password } = data;

        if (!email || !password) {
            throw new AppError(400, 'Please provide email and password');
        }

        const user = await User.findOne({ email });
        if (!user) {
            throw new AppError(401, 'Invalid credentials');
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            throw new AppError(401, 'Invalid credentials');
        }

        const token = generateToken(user._id);

        return {
            user: {
                id: user._id,
                username: user.username,
                email: user.email
            },
            token
        };
    }
}

export default new AuthService();
