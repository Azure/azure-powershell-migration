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
import { ConsoleFeature } from "./features/Console";
import { CustomViewsFeature } from "./features/CustomViews";
import { DebugSessionFeature } from "./features/DebugSession";
import { ExamplesFeature } from "./features/Examples";
import { ExpandAliasFeature } from "./features/ExpandAlias";
import { ExtensionCommandsFeature } from "./features/ExtensionCommands";
import { ExternalApiFeature } from "./features/ExternalApi";
import { FindModuleFeature } from "./features/FindModule";
import { GenerateBugReportFeature } from "./features/GenerateBugReport";
import { GetCommandsFeature } from "./features/GetCommands";
import { HelpCompletionFeature } from "./features/HelpCompletion";
import { ISECompatibilityFeature } from "./features/ISECompatibility";
import { NewFileOrProjectFeature } from "./features/NewFileOrProject";
import { OpenInISEFeature } from "./features/OpenInISE";
import { PesterTestsFeature } from "./features/PesterTests";
import { PickPSHostProcessFeature, PickRunspaceFeature } from "./features/DebugSession";
import { RemoteFilesFeature } from "./features/RemoteFiles";
import { RunCodeFeature } from "./features/RunCode";
import { ShowHelpFeature } from "./features/ShowHelp";
import { SpecifyScriptArgsFeature } from "./features/DebugSession";
import { GetAstFeature } from './features/GetAst';
import { Logger, LogLevel } from "./logging";
import { SessionManager } from "./session";
import Settings = require("./settings");
import { PowerShellLanguageId } from "./utils";
import { LanguageClientConsumer } from "./languageClientConsumer";
import { GetDiagnosticFeature } from "./features/GetDiagnostics";
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
        // new ExamplesFeature(),
        // new GenerateBugReportFeature(sessionManager),
        // new ISECompatibilityFeature(),
        // new OpenInISEFeature(),
        // new PesterTestsFeature(sessionManager),
        // new RunCodeFeature(sessionManager),
        new CodeActionsFeature(logger),
        // new SpecifyScriptArgsFeature(context),
    ]

    // Features and command registrations that require language client
    languageClientConsumers = [
        // new GetDiagnosticFeature(logger, context)
        // new GetAstFeature(logger, context),
        // new ConsoleFeature(logger),
        // new ExpandAliasFeature(logger),
        // new GetCommandsFeature(logger),
        // new ShowHelpFeature(logger),
        // new FindModuleFeature(),
        // new ExtensionCommandsFeature(logger),
        // new NewFileOrProjectFeature(),
        // new RemoteFilesFeature(),
        // new DebugSessionFeature(context, sessionManager, logger),
        // new PickPSHostProcessFeature(),
        // new HelpCompletionFeature(logger),
        // new CustomViewsFeature(),
        // new PickRunspaceFeature(),
        // new ExternalApiFeature(sessionManager, logger)
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