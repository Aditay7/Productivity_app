export class AppError extends Error {
    constructor(statusCode, message, isOperational = true) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        Object.setPrototypeOf(this, AppError.prototype);
    }
}

export const errorHandler = (err, _req, res, _next) => {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json({
            success: false,
            error: err.message,
        });
    }

    // Mongoose errors
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            success: false,
            error: 'Validation error',
            message: err.message,
        });
    }

    if (err.name === 'CastError') {
        return res.status(400).json({
            success: false,
            error: 'Invalid ID format',
        });
    }

    // Default error
    console.error('Unhandled error:', err);
    return res.status(500).json({
        success: false,
        error: 'Internal server error',
    });
};

export const notFoundHandler = (_req, res) => {
    res.status(404).json({
        success: false,
        error: 'Route not found',
    });
};
