/**
 * Query optimization utilities
 */

/**
 * Build optimized pagination
 */
const buildPagination = (page = 1, limit = 20) => {
    const parsedPage = Math.max(1, parseInt(page));
    const parsedLimit = Math.min(100, Math.max(1, parseInt(limit))); // Max 100 items
    const skip = (parsedPage - 1) * parsedLimit;

    return {
        page: parsedPage,
        limit: parsedLimit,
        skip
    };
};

/**
 * Build search filter with text index
 */
const buildSearchFilter = (fields, query) => {
    if (!query || query.trim() === '') {
        return {};
    }

    const searchRegex = new RegExp(query.trim(), 'i');
    return {
        $or: fields.map(field => ({
            [field]: searchRegex }))
    };
};

/**
 * Get lean query with selected fields
 */
const selectFields = (fields) => {
    return fields.join(' ');
};

/**
 * Build aggregation pipeline for counts
 */
const buildCountPipeline = (matchStage) => {
    return [
        { $match: matchStage },
        { $count: 'total' }
    ];
};

/**
 * Build efficient lookup pipeline
 */
const buildLookupPipeline = (from, localField, foreignField, as) => {
    return {
        $lookup: {
            from,
            localField,
            foreignField,
            as
        }
    };
};

module.exports = {
    buildPagination,
    buildSearchFilter,
    selectFields,
    buildCountPipeline,
    buildLookupPipeline
};