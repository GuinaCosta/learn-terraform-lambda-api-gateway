"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.otlEvent = void 0;
const otlUseCase_1 = require("../../use_cases/otlUseCase");
const otlEvent = async (event) => {
    const { getNewOtl } = (0, otlUseCase_1.otlUseCase)();
    const request = JSON.parse(typeof event.body === "string" ? event.body : "{}");
    console.log(request);
    const newOtl = await getNewOtl(request);
    const otlResponse = {
        newOtl: newOtl.newOtl,
        oldOtlIsValid: newOtl.oldOtlIsValid
    };
    const result = {
        statusCode: 200,
        body: JSON.stringify(otlResponse)
    };
    return result;
};
exports.otlEvent = otlEvent;
