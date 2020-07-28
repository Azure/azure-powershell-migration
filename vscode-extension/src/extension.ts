// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { getSrcVersion } from './selectVersion';
import { displayUnderline } from './displayUnderline';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
import { COMMAND, QuickFixer, QuickFixinfo } from './quickFix';
import { subscribeToDocumentChanges } from './diagnostics';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('"azure-powershell-migration" is now activating ...');

	let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
		// Get source version
		var sourceVersion =await getSrcVersion();
		
		if (sourceVersion != undefined) {
			vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
			
			// Get Mapping according to srcVersion
			var targetCmdlets = loadLatestVersionCmdletSpec();
			var sourceCmdlets = loadSrcVersionCmdletSpec(sourceVersion);
			var aliasMapping = loadAliasMapping();

			// update editor
			// displayUnderline(context, sourceCmdlets, targetCmdlets, aliasMapping);
		}
	});

	var quickFixer = new QuickFixer();
	let codeActionProvider = vscode.languages.registerCodeActionsProvider({language: 'powershell'}, quickFixer, {
		providedCodeActionKinds: QuickFixer.providedCodeActionKinds
	});
	context.subscriptions.push(disposable, codeActionProvider);

	const breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	context.subscriptions.push(breakingChangeDiagnostics);
	subscribeToDocumentChanges(context, breakingChangeDiagnostics);
	context.subscriptions.push(
		vscode.languages.registerCodeActionsProvider({language: 'powershell'}, new QuickFixinfo(), {
			providedCodeActionKinds: QuickFixinfo.providedCodeActionKinds
		})
	);

	context.subscriptions.push(
		vscode.commands.registerCommand(COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/azure/migrate-from-azurerm-to-az?view=azps-4.4.0')))
	);

	console.log('Congratulations, your extension "azure-powershell-migration" is now active!');
}

// this method is called when your extension is deactivated
export function deactivate() {}
