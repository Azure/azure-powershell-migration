/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import fs = require("fs");
import os = require("os");
import path = require("path");
import vscode = require("vscode");
import utils = require("./utils");

export enum LogLevel {
    Diagnostic,
    Verbose,
    Normal,
    Warning,
    Error,
}

/** Interface for logging operations. New features should use this interface for the "type" of logger.
 *  This will allow for easy mocking of the logger during unit tests.
 */
export interface ILogger {
    write(message: string, ...additionalMessages: string[]);
    writeDiagnostic(message: string, ...additionalMessages: string[]);
    writeVerbose(message: string, ...additionalMessages: string[]);
    writeWarning(message: string, ...additionalMessages: string[]);
    writeAndShowWarning(message: string, ...additionalMessages: string[]);
    writeError(message: string, ...additionalMessages: string[]);
}

export class Logger implements ILogger {

    public logBasePath: string;
    public logSessionPath: string;
    public MinimumLogLevel: LogLevel = LogLevel.Normal;

    private commands: vscode.Disposable[];
    private logChannel: vscode.OutputChannel;
    private logFilePath: string;

    constructor() {
        this.logChannel = vscode.window.createOutputChannel("Azure PowerShell Extension Logs");

        this.logBasePath = path.resolve(__dirname, "../../logs");
        utils.ensurePathExists(this.logBasePath);

        this.commands = [
            vscode.commands.registerCommand(
                "AzurePowerShell.ShowLogs",
                () => { this.showLogPanel(); }),

            vscode.commands.registerCommand(
                "AzurePowerShell.OpenLogFolder",
                () => { this.openLogFolder(); }),
        ];
    }

    public dispose(): void {
        this.commands.forEach((command) => { command.dispose(); });
        this.logChannel.dispose();
    }

    public getLogFilePath(baseName: string): string {
        return path.resolve(this.logSessionPath, `${baseName}.log`);
    }

    public writeAtLevel(logLevel: LogLevel, message: string, ...additionalMessages: string[]): void {
        if (logLevel >= this.MinimumLogLevel) {
            this.writeLine(message, logLevel);

            additionalMessages.forEach((line) => {
                this.writeLine(line, logLevel);
            });
        }
    }

    public write(message: string, ...additionalMessages: string[]): void {
        this.writeAtLevel(LogLevel.Normal, message, ...additionalMessages);
    }

    public writeDiagnostic(message: string, ...additionalMessages: string[]): void {
        this.writeAtLevel(LogLevel.Diagnostic, message, ...additionalMessages);
    }

    public writeVerbose(message: string, ...additionalMessages: string[]): void {
        this.writeAtLevel(LogLevel.Verbose, message, ...additionalMessages);
    }

    public writeWarning(message: string, ...additionalMessages: string[]): void {
        this.writeAtLevel(LogLevel.Warning, message, ...additionalMessages);
    }

    public writeAndShowWarning(message: string, ...additionalMessages: string[]): void {
        this.writeWarning(message, ...additionalMessages);

        vscode.window.showWarningMessage(message, "Show Logs").then((selection) => {
            if (selection !== undefined) {
                this.showLogPanel();
            }
        });
    }

    public writeError(message: string, ...additionalMessages: string[]): void {
        this.writeAtLevel(LogLevel.Error, message, ...additionalMessages);
    }

    public writeAndShowError(message: string, ...additionalMessages: string[]): void {
        this.writeError(message, ...additionalMessages);

        vscode.window.showErrorMessage(message, "Show Logs").then((selection) => {
            if (selection !== undefined) {
                this.showLogPanel();
            }
        });
    }

    public async writeAndShowErrorWithActions(
        message: string,
        actions: { prompt: string; action: () => Promise<void> }[]): Promise<void> {
        this.writeError(message);

        const fullActions = [
            ...actions,
            { prompt: "Show Logs", action: async () => { this.showLogPanel(); } },
        ];

        const actionKeys: string[] = fullActions.map((action) => action.prompt);

        const choice = await vscode.window.showErrorMessage(message, ...actionKeys);
        if (choice) {
            for (const action of fullActions) {
                if (choice === action.prompt) {
                    await action.action();
                    return;
                }
            }
        }
    }

    public startNewLog(minimumLogLevel = "Normal"): void {
        this.MinimumLogLevel = this.logLevelNameToValue(minimumLogLevel.trim());

        this.logSessionPath =
            path.resolve(
                this.logBasePath,
                `${Math.floor(Date.now() / 1000)}-${vscode.env.sessionId}`);

        this.logFilePath = this.getLogFilePath("azps-tools");

        utils.ensurePathExists(this.logSessionPath);
    }

    private logLevelNameToValue(logLevelName: string): LogLevel {
        switch (logLevelName.toLowerCase()) {
            case "diagnostic": return LogLevel.Diagnostic;
            case "verbose": return LogLevel.Verbose;
            case "normal": return LogLevel.Normal;
            case "warning": return LogLevel.Warning;
            case "error": return LogLevel.Error;
            default: return LogLevel.Normal;
        }
    }

    private showLogPanel() {
        this.logChannel.show();
    }

    private openLogFolder() {
        if (this.logSessionPath) {
            // Open the folder in VS Code since there isn't an easy way to
            // open the folder in the platform's file browser
            vscode.commands.executeCommand(
                "vscode.openFolder",
                vscode.Uri.file(this.logSessionPath),
                true);
        }
    }

    private writeLine(message: string, level: LogLevel = LogLevel.Normal) {
        const now = new Date();
        const timestampedMessage =
            `${now.toLocaleDateString()} ${now.toLocaleTimeString()} [${LogLevel[level].toUpperCase()}] - ${message}`;

        this.logChannel.appendLine(timestampedMessage);
        if (this.logFilePath) {
            fs.appendFile(
                this.logFilePath,
                timestampedMessage + os.EOL,
                (err) => {
                    if (err) {
                        // tslint:disable-next-line:no-console
                        console.log(`Error writing to azps-tools log file: ${err}`);
                    }
                });
        }
    }
}
