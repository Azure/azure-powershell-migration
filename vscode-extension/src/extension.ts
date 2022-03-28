/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { QuickFixProvider } from './quickFix';
import { updateDiagnostics, refreshDiagnosticsChange } from './diagnostic';
import {
    getPlatformDetails,
    OperatingSystem,
    PowerShellExeFinder
} from './platform';
import { Logger } from './logging';
import { PowershellProcess } from './powershell';
import { debounce } from './utils';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const PackageJSON = require('../package.json');

const powershell = new PowershellProcess();

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export async function activate(
    context: vscode.ExtensionContext
): Promise<void> {
    // let disposable = vscode.commands.registerCommand('azps-tools.selectVersion', async () => {
    //     //TODO: build one selection quickbox
    // });

    //start the logger
    const log = new Logger();

    //check for existence of powershell
    const powershellExistence = checkPowershell(log);
    if (!powershellExistence) {
        return;
    }

    //select azureRmVersion and azVersion(hard code)
    const azureRmVersion = '6.13.1';
    const azVersion = '6.1.0';

    //start a powershell process
    log.write('Starting PowerShell process...');
    try {
        await powershell.start();
        log.write('PowerShell process started successfully.');
    } catch (e) {
        log.writeError(`Cannot start PowerShell process. Error: ${e.message}.`);
    }

    //check for existence of module
    log.write('Checking required modules...');
    if (checkModule(powershell, log)) {
        log.write('Required modules are installed.');
    } else {
        log.writeError('Required modules are not installed.');
        return;
    }

    //initialize the diagnastic collection
    const diagCollection =
        vscode.languages.createDiagnosticCollection('azps-tools');

    registerHandlers(context, diagCollection, azureRmVersion, azVersion, log);

    //quick fix action
    const quickFixProvider = new QuickFixProvider(diagCollection);
    context.subscriptions.push(
        vscode.languages.registerCodeActionsProvider(
            { language: 'powershell' },
            quickFixProvider,
            {
                providedCodeActionKinds:
                    QuickFixProvider.providedCodeActionKinds
            }
        )
    );
}

// this method is called when your extension is deactivated
export function deactivate(): void {
    try {
        powershell.stop();
    } catch {
        // deactivating extension, exceptions should be swallowed
    }
}

/**
 * register handlers
 * @param context : context of extension
 * @param diagcCollection : manage the diagnostics
 * @param azureRmVersion : version of azureRM
 * @param azVersion : version of az
 * @param log : Logger
 */
function registerHandlers(
    context: vscode.ExtensionContext,
    diagcCollection: vscode.DiagnosticCollection,
    azureRmVersion: string,
    azVersion: string,
    log: Logger
): void {
    // analyze current document - this should only be done once
    if (vscode.window.activeTextEditor) {
        updateDiagnostics(
            vscode.window.activeTextEditor.document.uri,
            diagcCollection,
            powershell,
            azureRmVersion,
            azVersion,
            log
        );
    }

    //do the analysis when the file is opened
    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument((editor) => {
            if (editor && editor.languageId === 'powershell') {
                updateDiagnostics(
                    editor.uri,
                    diagcCollection,
                    powershell,
                    azureRmVersion,
                    azVersion,
                    log
                );
            }
        })
    );

    //do the analysis when the file is saved
    context.subscriptions.push(
        vscode.workspace.onDidSaveTextDocument((editor) => {
            if (editor && editor.languageId === 'powershell') {
                updateDiagnostics(
                    editor.uri,
                    diagcCollection,
                    powershell,
                    azureRmVersion,
                    azVersion,
                    log
                );
            }
        })
    );

    //do the analysis when the file is changed
    const delay = 1000;
    const debouncedCallback = debounce(
        (event: vscode.TextDocumentChangeEvent) => {
            refreshDiagnosticsChange(
                event.document.getText(),
                event.document.uri,
                diagcCollection,
                powershell,
                azureRmVersion,
                azVersion,
                log
            );
        },
        delay
    );
    context.subscriptions.push(
        vscode.workspace.onDidChangeTextDocument((event) => {
            if (event && event.document.languageId === 'powershell') {
                debouncedCallback(event);
            }
        })
    );
}

/**
 * check whether the module exists
 * if not exist : suggest installing the module
 * @param powershell : powershell process manager
 * @param log : Logger
 * @returns : if the module exists
 */
function checkModule(powershell: PowershellProcess, log: Logger): boolean {
    let moduleName = 'Az.Tools.Migration';
    if (!powershell.checkModuleExist(moduleName)) {
        log.writeAndShowErrorWithActions(
            'Please install the Az.Tools.Migration PowerShell module.',
            [
                {
                    prompt: 'Get Az.Tools.Migration',
                    action: async () => {
                        const getPSUri = vscode.Uri.parse(
                            'https://docs.microsoft.com/en-us/powershell/azure/quickstart-migrate-azurerm-to-az-automatically#requirements'
                        );
                        vscode.env.openExternal(getPSUri);
                    }
                }
            ]
        );
        return false;
    }

    moduleName = 'PSScriptAnalyzer';
    if (!powershell.checkModuleExist(moduleName)) {
        log.writeAndShowErrorWithActions(
            'Please install the PSScriptAnalyzer PowerShell module.',
            [
                {
                    prompt: 'Get PSScriptAnalyzer',
                    action: async () => {
                        const getPSUri = vscode.Uri.parse(
                            'https://github.com/PowerShell/PSScriptAnalyzer#installation'
                        );
                        vscode.env.openExternal(getPSUri);
                    }
                }
            ]
        );
        return false;
    }

    return true;
}

/**
 * Check whether the powershell exists in your machine
 * if not exist : suggest installing Powershell for yourself
 * @param log : Logger
 * @returns : if the powershell exists
 */
function checkPowershell(log: Logger): boolean {
    const platformDetails = getPlatformDetails();
    const osBitness = platformDetails.isOS64Bit ? '64-bit' : '32-bit';
    const procBitness = platformDetails.isProcess64Bit ? '64-bit' : '32-bit';
    log.write(
        `Visual Studio Code v${vscode.version} ${procBitness}`,
        `${PackageJSON.displayName} Extension v${PackageJSON.version}`,
        `Operating System: ${
            OperatingSystem[platformDetails.operatingSystem]
        } ${osBitness}`
    );
    log.startNewLog('normal');

    //check whether the powershell exists
    log.write('Checking if PowerShell is installed...');
    const powershellExeFinder = new PowerShellExeFinder();
    let powerShellExeDetails;
    try {
        powerShellExeDetails =
            powershellExeFinder.getFirstAvailablePowerShellInstallation();
    } catch (e) {
        log.writeError(
            `Error occurred while searching for a PowerShell executable:\n${e}`
        );
    }
    if (!powerShellExeDetails) {
        const message =
            'Unable to find PowerShell.' +
            ' Do you have PowerShell installed?' +
            ' You can also configure custom PowerShell installations' +
            " with the 'powershell.powerShellAdditionalExePaths' setting.";

        log.writeAndShowErrorWithActions(message, [
            {
                prompt: 'Get PowerShell',
                action: async () => {
                    const getPSUri = vscode.Uri.parse(
                        'https://aka.ms/get-powershell-vscode'
                    );
                    vscode.env.openExternal(getPSUri);
                }
            }
        ]);
        return false;
    } else {
        log.write('PowerShell is installed.');
        return true;
    }
}
