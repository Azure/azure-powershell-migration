/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import {BreakingChangeInfo} from './quickFix';
import {updateDiagnostics} from './diagnostic'
import {
    getPlatformDetails, IPlatformDetails, IPowerShellExeDetails,
    OperatingSystem, PowerShellExeFinder } from "./platform";
import { Logger } from "./logging";
import { PowershellProcess } from './powershell';

const PackageJSON: any = require("../package.json");
let powershell = new PowershellProcess();

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export async function activate(context: vscode.ExtensionContext) {
	
	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "demo-client" is now active!');
	let disposable = vscode.commands.registerCommand('azps-tools.selectVersion', async () => {
		//TODO: build one selection quickbox
    });

	//start the logger
	let log;
	log = new Logger();
	let platformDetails = getPlatformDetails();
	const osBitness = platformDetails.isOS64Bit ? "64-bit" : "32-bit";
    const procBitness = platformDetails.isProcess64Bit ? "64-bit" : "32-bit";
	log.write(
		`Visual Studio Code v${vscode.version} ${procBitness}`,
		`${PackageJSON.displayName} Extension v${PackageJSON.version}`,
		`Operating System: ${OperatingSystem[platformDetails.operatingSystem]} ${osBitness}`);
	log.startNewLog('normal');

	//check whether the powershell exists
	var powershellExeFinder = new PowerShellExeFinder();
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
		return;
	}
	else
	{
		log.write("Have found powershell!");
	}

	//select azureRmVersion and azVersion(hard code)
	const azureRmVersion = "6.13.1";
	const azVersion = "6.1.0";

	//start a powershell process
	try {
		powershell.start();
		log.write("Start powershell successed!");
	}
	catch(e) {
		log.writeError("Can't start the powershell : " + e.message);
	}
	
	//check for existence of module
	let moduleExistence = await checkModule(powershell, log);
	if (moduleExistence)
		log.write('The module exist!');

	//build the diagnastic
	const collection = vscode.languages.createDiagnosticCollection('test');
	if (vscode.window.activeTextEditor) {
		updateDiagnostics(vscode.window.activeTextEditor.document.uri, collection, powershell, azureRmVersion, azVersion, log);
	}

	//do the analysis when the file is opened
	context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(editor => {
		if (editor && editor.languageId == "powershell") {
			updateDiagnostics(editor.uri, collection, powershell, azureRmVersion, azVersion, log);
		}
	}))

	//do the analysis when the file is saved
	context.subscriptions.push(vscode.workspace.onDidSaveTextDocument(editor => {
		if (editor && editor.languageId == "powershell") {
			updateDiagnostics(editor.uri, collection, powershell, azureRmVersion, azVersion, log);
		}
	}))

	//quick fix action
	let breakingChangeInfo = new BreakingChangeInfo();
	context.subscriptions.push(
		vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, breakingChangeInfo , {
			providedCodeActionKinds: BreakingChangeInfo.providedCodeActionKinds
		})
	);
}

// this method is called when your extension is deactivated
export function deactivate() {
	try {
		powershell.stop();
	}
	catch{}
}

async function checkModule(powershell : PowershellProcess, log : Logger){
	//check whether the module exists
	//if not exist : suggest installing the module
	const moduleName = "Az.Tools.Migration";
	powershell.getSystemModulePath();
	if (!powershell.checkModuleExist(moduleName)){
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
