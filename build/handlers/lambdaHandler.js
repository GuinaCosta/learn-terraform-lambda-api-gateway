"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.lambdaHandler = void 0;
const otlEvent_1 = require("../infrastructure/events/otlEvent");
const lambdaHandler = async (event) => {
    const queries = JSON.stringify(event.queryStringParameters);
    const body = typeof event.body === "string" ? JSON.parse(event.body) : "";
    const notImplementedResult = {
        statusCode: 406,
        body: ""
    };
    console.log(queries);
    console.log(body);
    switch (event.resource) {
        case "/otl":
            return (0, otlEvent_1.otlEvent)(event);
        case "/applicant/business":
            return notImplementedResult;
        case "/property":
            return notImplementedResult;
        default:
            return notImplementedResult;
    }
};
exports.lambdaHandler = lambdaHandler;
