import * as vscode from 'vscode';
import { getSrcVersion } from './selectVersion';
import { DiagnosticsManagement } from './diagnostics';

export function activate(context: vscode.ExtensionContext) {
	console.log('"azure-powershell-migration" is now activating ...');
	var diagnosticsManagement=new DiagnosticsManagement(context);

	let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
		// Get source version
		var sourceVersion =await getSrcVersion();
		
		// Refresh mapping every time change source version
		if (sourceVersion != undefined) {
			vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
			diagnosticsManagement.refreshMapping(context,sourceVersion);
		}
	});

	context.subscriptions.push(disposable);

	console.log('Congratulations, your extension "azure-powershell-migration" is now active!');
}

// this method is called when your extension is deactivated
export function deactivate() {}
