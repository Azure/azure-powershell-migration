// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { getSrcVersion } from './selectVersion';
import { displayUnderline } from './displayUnderline';
import { loadAzCmdletSpec, loadAzureRMCmdletSpec } from './aliasMapping';
import { QuickFixer } from './quickFix';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('"azure-powershell-migration" is now activating ...');

	let targetCmdlets = new Map<string, any>();
	let sourceCmdlets = new Map<string, any>();

	let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
		// Get source version
		const srcVersion=await getSrcVersion();
		vscode.window.showInformationMessage(`Updating powershell scripts from  '${srcVersion}' to latest`);
		
		// Get Mapping according to srcVersion
		targetCmdlets = loadAzCmdletSpec();
		sourceCmdlets = loadAzureRMCmdletSpec();

		// update editor
		displayUnderline(context, sourceCmdlets, targetCmdlets);
	});

	let codeActionProvider = vscode.languages.registerCodeActionsProvider({scheme: 'file'}, new QuickFixer(), {
		providedCodeActionKinds: QuickFixer.providedCodeActionKinds
	});

	context.subscriptions.push(disposable, codeActionProvider);

	console.log('Congratulations, your extension "azure-powershell-migration" is now active!');
}

// this method is called when your extension is deactivated
export function deactivate() {}
