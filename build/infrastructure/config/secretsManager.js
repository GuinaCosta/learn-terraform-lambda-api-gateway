"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApplicationSecretsManager = void 0;
const config_1 = require("./config");
const aws_sdk_1 = require("aws-sdk");
class ApplicationSecretsManager {
    static async getSecret() {
        if (!ApplicationSecretsManager.secret) {
            const secretsManager = new aws_sdk_1.SecretsManager();
            try {
                const secretValue = await secretsManager
                    .getSecretValue({ SecretId: config_1.CONFIGURATIONS.SECRET_MANAGER_ARN })
                    .promise();
                if (secretValue && secretValue.SecretString)
                    ApplicationSecretsManager.secret = {
                        soApiToken: secretValue.SecretString
                    };
            }
            catch (error) {
                console.log(error);
                throw error;
            }
        }
        return ApplicationSecretsManager.secret;
    }
}
exports.ApplicationSecretsManager = ApplicationSecretsManager;
