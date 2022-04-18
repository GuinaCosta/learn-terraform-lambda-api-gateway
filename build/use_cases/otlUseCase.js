"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.otlUseCase = void 0;
const otlClient_1 = require("../infrastructure/http_client/otlClient");
function otlUseCase() {
    const { validateOtl } = (0, otlClient_1.otlClient)();
    const getNewOtl = async (otlRequest) => {
        const otlValidation = {
            otlId: otlRequest.otlId,
            merchantId: otlRequest.merchantId
        };
        const newOtl = await validateOtl(otlValidation);
        return newOtl;
    };
    return {
        getNewOtl
    };
}
exports.otlUseCase = otlUseCase;
