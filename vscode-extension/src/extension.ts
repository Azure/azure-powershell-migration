// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { getSrcVersion } from './selectVersion';
import { displayUnderline } from './displayUnderline';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec } from './aliasMapping';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('"azure-powershell-migration" is now activating ...');

	let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
		// Get source version
		var sourceVersion =await getSrcVersion();
		
		if(sourceVersion!=undefined){
			vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
		
			// Get Mapping according to srcVersion
			const targetCmdlets = loadLatestVersionCmdletSpec();
			const sourceCmdlets = loadSrcVersionCmdletSpec(sourceVersion);
	
			// update editor
			displayUnderline(context, sourceCmdlets, targetCmdlets);
		}

	});

	context.subscriptions.push(disposable);

	console.log('Congratulations, your extension "azure-powershell-migration" is now active!');
}

// this method is called when your extension is deactivated
export function deactivate() {}
