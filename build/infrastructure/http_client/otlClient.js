"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.otlClient = void 0;
const axios_1 = require("axios");
const config_1 = require("../config/config");
const clientConstants_1 = require("./clientConstants");
function otlClient() {
    const validateOtl = async (otlRequest) => {
        try {
            const response = await axios_1.default.post(`${config_1.CONFIGURATIONS.SO_API_URL}/otl`, otlRequest, {
                headers: await (0, clientConstants_1.defaultHeaders)()
            });
            return response.data;
        }
        catch (error) {
            console.log(error);
            throw error;
        }
    };
    return {
        validateOtl
    };
}
exports.otlClient = otlClient;
