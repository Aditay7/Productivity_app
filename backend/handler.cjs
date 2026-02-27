'use strict';
/**
 * AWS Lambda handler — CommonJS wrapper for ES module Express app.
 *
 * We use a .cjs extension to stay in CommonJS mode even though the rest of
 * the project has "type": "module". This lets us use require() for
 * @vendia/serverless-express while dynamically importing the ESM app.
 *
 * The app and handler are cached at module level so they survive warm starts.
 */

const serverless = require('@vendia/serverless-express');

let cachedHandler;

module.exports.handler = async (event, context) => {
    // Keep Lambda function alive for DB connection reuse
    context.callbackWaitsForEmptyEventLoop = false;

    if (!cachedHandler) {
        // Dynamic import to load the ES module app
        const { default: app } = await import('./src/app.js');
        cachedHandler = serverless({ app });
    }

    return cachedHandler(event, context);
};
