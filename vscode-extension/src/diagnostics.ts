import * as vscode from 'vscode';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
import { GET_INFO_COMMAND,GET_DEPRE_INFO_COMMAND,DEPRECATED_CMDLET, CMDLET_RENAME, CORRECT_CMDLET, CmdletRenameInfo, DeprecatedCmdletInfo } from './quickFix';
	

export class DiagnosticsManagement {
	sourceCmdlets: Map<string, string> = new Map();
	targetCmdlets: Map<string, string> = new Map();
	aliasMapping: Map<string, string> = new Map();
	breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	cmdletRenameInfo = new CmdletRenameInfo();
	deprecatedCmdletInfo=new DeprecatedCmdletInfo();

	constructor(context: vscode.ExtensionContext) {
		// Register new action
		context.subscriptions.push(this.breakingChangeDiagnostics);

		context.subscriptions.push(
			vscode.window.onDidChangeActiveTextEditor(editor => {
				if (editor) {
					this.refreshTextEditorHelper(editor.document);
				}
			})
		);

		context.subscriptions.push(
			vscode.workspace.onDidChangeTextDocument(e => this.refreshTextEditorHelper(e.document))
		);

		context.subscriptions.push(
			vscode.workspace.onDidCloseTextDocument(doc => this.breakingChangeDiagnostics.delete(doc.uri))
		);

		context.subscriptions.push(
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.cmdletRenameInfo , {
				providedCodeActionKinds: CmdletRenameInfo.providedCodeActionKinds
			})
		);

		context.subscriptions.push(
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.deprecatedCmdletInfo, {
				providedCodeActionKinds: DeprecatedCmdletInfo.providedCodeActionKinds
			})
		);
		context.subscriptions.push(
			vscode.commands.registerCommand(GET_INFO_COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/module')))
		);
		context.subscriptions.push(
			vscode.commands.registerCommand(GET_DEPRE_INFO_COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/azure/migrate-az-1.0.0?view=azps-4.4.0#temporary-removal-of-user-login-using-pscredential')))
		);
		
	}

	refreshMapping(context: vscode.ExtensionContext, srcVersion: string): void {
		// Get Mapping according to srcVersion
		this.sourceCmdlets = loadSrcVersionCmdletSpec(srcVersion);
		this.targetCmdlets = loadLatestVersionCmdletSpec();
		this.aliasMapping = loadAliasMapping();

		this.refreshTextEditor(context);		
	}

	refreshTextEditor(context: vscode.ExtensionContext): void {
		
		this.cmdletRenameInfo.updateMapping(this.sourceCmdlets,this.targetCmdlets,this.aliasMapping);
		this.deprecatedCmdletInfo.updateMapping(this.sourceCmdlets,this.targetCmdlets,this.aliasMapping);

		if (vscode.window.activeTextEditor) {
			this.refreshTextEditorHelper(vscode.window.activeTextEditor.document);
		}		
	}


	refreshTextEditorHelper(doc: vscode.TextDocument): void {
		const diagnostics: vscode.Diagnostic[] = [];

		let activeEditor = vscode.window.activeTextEditor;
		if (activeEditor) {
			const text = activeEditor.document.getText();
			let re = new RegExp(/[a-zA-z]+-[a-zA-z]+/g);
			let match=null;
			while ((match = re.exec(text))) {
				var cmdletName = match[0].toString().toLowerCase();
				var breakingChangeType = this.getBreakingChangeType(cmdletName);
				const startPos = activeEditor.document.positionAt(match.index);
				const endPos = activeEditor.document.positionAt(match.index + match[0].length);
				const range = new vscode.Range(startPos, endPos);

				switch (breakingChangeType) {
					case CMDLET_RENAME: {
						const diagnostic = new vscode.Diagnostic(range, "This cmdlet change its name.",
							vscode.DiagnosticSeverity.Information);
						diagnostic.code = CMDLET_RENAME;
						diagnostic.severity = 1;
						diagnostics.push(diagnostic);
						break;
					}
					case DEPRECATED_CMDLET: {
						const diagnostic = new vscode.Diagnostic(range, "This is a deprecated cmdlet.",
							vscode.DiagnosticSeverity.Information);
						diagnostic.code = DEPRECATED_CMDLET;
						diagnostic.severity = 0;
						diagnostics.push(diagnostic);
						break;
					}
					case CORRECT_CMDLET: {
						continue;
					}
				}
			}
		}
		this.breakingChangeDiagnostics.set(doc.uri, diagnostics);
	}

	getBreakingChangeType(cmdletName: string) {
		cmdletName = cmdletName.toLowerCase();
		if (this.sourceCmdlets.has(cmdletName)) {
		// if find cmlet in sourceCmdlet
			if (this.aliasMapping.has(cmdletName) && 
					this.targetCmdlets.has(this.aliasMapping.get(cmdletName)!.toLowerCase())) {
				return CMDLET_RENAME;
			} else {
				return DEPRECATED_CMDLET;
			}
		}
		return CORRECT_CMDLET;
	}
	
	getInfoUrl():string{
		return "";
	}
}