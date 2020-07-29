// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { getSrcVersion } from './selectVersion';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
import { QuickFixinfo, DepracatedCmdletinfo } from './quickFix';
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
			var sourceCmdlets = loadSrcVersionCmdletSpec(sourceVersion);
			var targetCmdlets = loadLatestVersionCmdletSpec();
			var aliasMapping = loadAliasMapping();

			quickFix(context, aliasMapping, sourceCmdlets, targetCmdlets);
		}
	});

	context.subscriptions.push(disposable);

	console.log('Congratulations, your extension "azure-powershell-migration" is now active!');
}

function quickFix(context: vscode.ExtensionContext, aliasMapping: Map<string, string>, sourceCmdlets: Map<string, any>, targetCmdlets: Map<string, any>) {
	const breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	context.subscriptions.push(breakingChangeDiagnostics);
	subscribeToDocumentChanges(context, breakingChangeDiagnostics, aliasMapping, sourceCmdlets, targetCmdlets);
	context.subscriptions.push(
		vscode.languages.registerCodeActionsProvider({language: 'powershell'}, new QuickFixinfo(aliasMapping, sourceCmdlets, targetCmdlets), {
			providedCodeActionKinds: QuickFixinfo.providedCodeActionKinds
		})
	);
	context.subscriptions.push(
		vscode.languages.registerCodeActionsProvider({language: 'powershell'}, new DepracatedCmdletinfo(aliasMapping, sourceCmdlets, targetCmdlets), {
			providedCodeActionKinds: DepracatedCmdletinfo.providedCodeActionKinds
		})
	);
}

// this method is called when your extension is deactivated
export function deactivate() {}
