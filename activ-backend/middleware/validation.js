/**
 * Request Validation Middleware
 * Validates request data before it reaches route handlers
 * Improves performance by failing fast on invalid requests
 */

const { body, query, param, validationResult } = require('express-validator');

/**
 * Handle validation errors
 */
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed',
            errors: errors.array().map(err => ({
                field: err.path || err.param,
                message: err.msg
            }))
        });
    }

    next();
};

/**
 * Login validation rules
 */
const validateLogin = [
    body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Must be a valid email')
    .normalizeEmail(),
    body('password')
    .trim()
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    handleValidationErrors
];

/**
 * Registration validation rules
 */
const validateRegistration = [
    body('fullName')
    .trim()
    .notEmpty().withMessage('Full name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Name must be 2-100 characters'),
    body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Must be a valid email')
    .normalizeEmail(),
    body('phoneNumber')
    .trim()
    .notEmpty().withMessage('Phone number is required')
    .matches(/^[\+]?[1-9][\d]{9,15}$/).withMessage('Invalid phone number format'),
    body('password')
    .trim()
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password must contain uppercase, lowercase, and number'),
    handleValidationErrors
];

/**
 * ObjectId validation
 */
const validateObjectId = (paramName = 'id') => [
    param(paramName)
    .matches(/^[0-9a-fA-F]{24}$/).withMessage(`Invalid ${paramName} format`),
    handleValidationErrors
];

/**
 * Query parameter validation for pagination
 */
const validatePagination = [
    query('page')
    .optional()
    .isInt({ min: 1 }).withMessage('Page must be a positive integer')
    .toInt(),
    query('limit')
    .optional()
    .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100')
    .toInt(),
    handleValidationErrors
];

/**
 * Company creation validation
 */
const validateCompany = [
    body('name')
    .trim()
    .notEmpty().withMessage('Company name is required')
    .isLength({ min: 2, max: 200 }).withMessage('Name must be 2-200 characters'),
    body('industry')
    .trim()
    .notEmpty().withMessage('Industry is required'),
    body('email')
    .optional()
    .trim()
    .isEmail().withMessage('Must be a valid email')
    .normalizeEmail(),
    body('mobile')
    .optional()
    .trim()
    .matches(/^[\+]?[1-9][\d]{9,15}$/).withMessage('Invalid phone number format'),
    handleValidationErrors
];

/**
 * Product creation validation
 */
const validateProduct = [
    body('companyId')
    .matches(/^[0-9a-fA-F]{24}$/).withMessage('Invalid companyId format'),
    body('name')
    .trim()
    .notEmpty().withMessage('Product name is required')
    .isLength({ min: 2, max: 200 }).withMessage('Name must be 2-200 characters'),
    body('category')
    .trim()
    .notEmpty().withMessage('Category is required'),
    body('price')
    .notEmpty().withMessage('Price is required')
    .isFloat({ min: 0 }).withMessage('Price must be a positive number')
    .toFloat(),
    body('priceUnit')
    .optional()
    .isIn(['one-time', 'per-hour', 'per-day', 'per-month', 'per-year'])
    .withMessage('Invalid price unit'),
    handleValidationErrors
];

/**
 * Discover query validation
 */
const validateDiscoverQuery = [
    query('memberId')
    .notEmpty().withMessage('memberId is required')
    .matches(/^[0-9a-fA-F]{24}$/).withMessage('Invalid memberId format'),
    query('query')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Search query too long'),
    ...validatePagination
];

module.exports = {
    validateLogin,
    validateRegistration,
    validateObjectId,
    validatePagination,
    validateCompany,
    validateProduct,
    validateDiscoverQuery,
    handleValidationErrors
};