// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { multiStepInput } from './multiStepInput';
import { displayUnderline } from './displayUnderline';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	const map = new Map();
	map.set("New-AzureRMResourceGroup", "New-AzResourceGroup");
	map.set("New-AzureRMAppservicePlan", "New-AzAppservicePlan")
	map.set("New-AzureRMWebApp", "New-AzWebApp");
	map.set("New-AzureRMSQLServer", "New-AzSQLServer");
	map.set("New-AzureRmSqlServerFirewallRule", "New-AzSqlServerFirewallRule");
	map.set("New-AzureRMSQLDatabase", "New-AzSQLDatabase");
	map.set("Set-AzureRMWebApp", "Set-AzWebApp");
	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "psmigration" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	let disposable = vscode.commands.registerCommand('psmigration.psMigration', async () => {
		let settings=await multiStepInput(context);
		displayUnderline(context, map);
	});

	context.subscriptions.push(disposable);


}

// this method is called when your extension is deactivated
export function deactivate() {}
