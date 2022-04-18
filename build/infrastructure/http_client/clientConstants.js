"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultHeaders = void 0;
const secretsManager_1 = require("../config/secretsManager");
async function defaultHeaders() {
    const secret = await secretsManager_1.ApplicationSecretsManager.getSecret();
    return {
        "Authorization": `Bearer ${secret.soApiToken}`
    };
}
exports.defaultHeaders = defaultHeaders;
