import { Request, Response, NextFunction } from 'express';
import { ApiResponse } from '../types';

export class AppError extends Error {
    constructor(
        public statusCode: number,
        public message: string,
        public isOperational = true
    ) {
        super(message);
        Object.setPrototypeOf(this, AppError.prototype);
    }
}

export const errorHandler = (
    err: Error | AppError,
    _req: Request,
    res: Response<ApiResponse>,
    _next: NextFunction
) => {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json({
            success: false,
            error: err.message,
        });
    }

    // Prisma errors
    if (err.name === 'PrismaClientKnownRequestError') {
        return res.status(400).json({
            success: false,
            error: 'Database error occurred',
        });
    }

    // Validation errors
    if (err.name === 'ZodError') {
        return res.status(400).json({
            success: false,
            error: 'Validation error',
            message: err.message,
        });
    }

    // Default error
    console.error('Unhandled error:', err);
    return res.status(500).json({
        success: false,
        error: 'Internal server error',
    });
};

export const notFoundHandler = (_req: Request, res: Response<ApiResponse>) => {
    res.status(404).json({
        success: false,
        error: 'Route not found',
    });
};
