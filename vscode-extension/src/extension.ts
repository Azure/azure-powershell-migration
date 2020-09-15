/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/
// import * as vscode from 'vscode';
"use strict";

import path = require("path");
import vscode = require("vscode");
import TelemetryReporter from "vscode-extension-telemetry";
import { DocumentSelector } from "vscode-languageclient";
import { CodeActionsFeature } from "./features/CodeActions";
import { Logger, LogLevel } from "./logging";
import { SessionManager } from "./session";
import Settings = require("./settings");
import { PowerShellLanguageId } from "./utils";
import { LanguageClientConsumer } from "./languageClientConsumer";
import { getSrcVersion } from "./selectVersion";

// The most reliable way to get the name and version of the current extension.
// tslint:disable-next-line: no-var-requires
const PackageJSON: any = require("../package.json");

// the application insights key (also known as instrumentation key) used for telemetry.

let logger: Logger;
let sessionManager: SessionManager;
let languageClientConsumers: LanguageClientConsumer[] = [];
let commandRegistrations: vscode.Disposable[] = [];
let telemetryReporter: TelemetryReporter;

const documentSelector: DocumentSelector = [
    { language: "powershell", scheme: "file" },
    { language: "Powershell", scheme: "file" },
    { language: "powershell", scheme: "untitled" },
];

export function activate(context: vscode.ExtensionContext): void {
    console.debug('===========================================');
    console.log('Congratulations, your extension "azure-powershell-migration" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json

    // Create the logger
    logger = new Logger();

    // Set the log level
    const extensionSettings = Settings.load();
    logger.MinimumLogLevel = LogLevel[extensionSettings.developer.editorServicesLogLevel];

    sessionManager =
        new SessionManager(
            logger,
            documentSelector,
            PackageJSON.displayName,
            PackageJSON.version,
            telemetryReporter);

    // Register commands that do not require Language client
    commandRegistrations = [
        new CodeActionsFeature(logger),
    ]

    // Features and command registrations that require language client
    languageClientConsumers = [
    ];

    sessionManager.setLanguageClientConsumers(languageClientConsumers);

    if (extensionSettings.startAutomatically) {
        sessionManager.start();
    }

    let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
        var sourceVersion = await getSrcVersion();
        vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
    });
    
    context.subscriptions.push(disposable);
}

export function deactivate(): void {
    // Clean up all extension features
    languageClientConsumers.forEach((languageClientConsumer) => {
        languageClientConsumer.dispose();
    });

    commandRegistrations.forEach((commandRegistration) => {
        commandRegistration.dispose();
    });

    // Dispose of the current session
    sessionManager.dispose();

    // Dispose of the logger
    logger.dispose();
}
