/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { QuickFixProvider } from './quickFix';
import { updateDiagnostics } from './diagnostic';
import {
    getPlatformDetails, OperatingSystem, PowerShellExeFinder
} from "./platform";
import { Logger } from "./logging";
import { PowershellProcess } from './powershell';
import * as utils from "./utils";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const PackageJSON = require('../package.json');

const powershell = new PowershellProcess();

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export async function activate(context: vscode.ExtensionContext): Promise<void> {

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
    const azureRmVersion = "6.13.1";
    const azVersion = "6.1.0";

    //start a powershell process
    try {
        powershell.start();
        log.write("Start powershell successed!");
    }
    catch (e) {
        log.writeError("Can't start the powershell : " + e.message);
    }

    //check for existence of module
    const moduleExistence = await checkModule(powershell, log);
    if (moduleExistence) { log.write('The module exist!'); }
    else {
        return;
    }

    //build the diagnastic
    const diagcCollection = vscode.languages.createDiagnosticCollection('azps-tools');

    registerHandlers(context, diagcCollection, azureRmVersion, azVersion, log);

    //quick fix action
    const quickFixProvider = new QuickFixProvider(diagcCollection);
    context.subscriptions.push(
        vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, quickFixProvider, {
            providedCodeActionKinds: QuickFixProvider.providedCodeActionKinds
        })
    );
}

// this method is called when your extension is deactivated
export function deactivate(): void {
    try {
        powershell.stop();
    }
    catch {
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
    log: Logger): void {
    if (vscode.window.activeTextEditor) {
        updateDiagnostics(vscode.window.activeTextEditor.document.uri, diagcCollection, powershell, azureRmVersion, azVersion, log);
    }

    //do the analysis when the file is opened
    context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(editor => {
        if (editor && editor.languageId == "powershell") {
            updateDiagnostics(editor.uri, diagcCollection, powershell, azureRmVersion, azVersion, log);
        }
    }));

    //do the analysis when the file is saved
    context.subscriptions.push(vscode.workspace.onDidSaveTextDocument(editor => {
        if (editor && editor.languageId == "powershell") {
            updateDiagnostics(editor.uri, diagcCollection, powershell, azureRmVersion, azVersion, log);
        }
    }));
}

/**
 * check whether the module exists
 * if not exist : suggest installing the module
 * @param powershell : powershell process manager
 * @param log : Logger
 * @returns : if the module exists
 */
function checkModule(powershell: PowershellProcess, log: Logger): boolean {
    const moduleName = "Az.Tools.Migration";
    powershell.getSystemModulePath();
    if (!powershell.checkModuleExist(moduleName)) {
        log.writeAndShowErrorWithActions("You have to install Az.Tools.Migration firstly!", [
            {
                prompt: "Get Az.Tools.Migration",
                action: async () => {
                    const getPSUri = vscode.Uri.parse("https://docs.microsoft.com/en-us/powershell/azure/quickstart-migrate-azurerm-to-az-automatically");
                    vscode.env.openExternal(getPSUri);
                },
            },
        ]);
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
    const osBitness = platformDetails.isOS64Bit ? "64-bit" : "32-bit";
    const procBitness = platformDetails.isProcess64Bit ? "64-bit" : "32-bit";
    log.write(
        `Visual Studio Code v${vscode.version} ${procBitness}`,
        `${PackageJSON.displayName} Extension v${PackageJSON.version}`,
        `Operating System: ${OperatingSystem[platformDetails.operatingSystem]} ${osBitness}`);
    log.startNewLog('normal');

    //check whether the powershell exists
    const powershellExeFinder = new PowerShellExeFinder();
    let powerShellExeDetails;
    try {
        powerShellExeDetails = powershellExeFinder.getFirstAvailablePowerShellInstallation();
    } catch (e) {
        log.writeError(`Error occurred while searching for a PowerShell executable:\n${e}`);
    }
    if (!powerShellExeDetails) {
        const message = "Unable to find PowerShell."
            + " Do you have PowerShell installed?"
            + " You can also configure custom PowerShell installations"
            + " with the 'powershell.powerShellAdditionalExePaths' setting.";

        log.writeAndShowErrorWithActions(message, [
            {
                prompt: "Get PowerShell",
                action: async () => {
                    const getPSUri = vscode.Uri.parse("https://aka.ms/get-powershell-vscode");
                    vscode.env.openExternal(getPSUri);
                },
            },
        ]);
        return false;
    }
    else {
        log.write("Have found powershell!");
        return true;
    }
}