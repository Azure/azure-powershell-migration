import * as vscode from 'vscode';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
import { DEPRECATED_CMDLET, CMDLET_RENAME, PARAMETER_CHANGE, CORRECT_CMDLET, CmdletRenameInfo, DepracatedCmdletInfo, ParameterChangeInfo } from './quickFix';

export class DiagnosticsManagement {
	sourceCmdlets: Map<string, string> = new Map();
	targetCmdlets: Map<string, string> = new Map();
	aliasMapping: Map<string, string> = new Map();
	breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	cmdletRenameInfo = new CmdletRenameInfo();
	depracatedCmdletInfo = new DepracatedCmdletInfo();
	parameterChangeInfo = new ParameterChangeInfo();

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
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.depracatedCmdletInfo, {
				providedCodeActionKinds: DepracatedCmdletInfo.providedCodeActionKinds
			})
		);

		context.subscriptions.push(
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.parameterChangeInfo , {
				providedCodeActionKinds: ParameterChangeInfo.providedCodeActionKinds
			})
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
		
		this.cmdletRenameInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);
		this.depracatedCmdletInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);
		this.parameterChangeInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);

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
			let match = null;
			while ((match = re.exec(text))) {
				var cmdletName = match[0].toString().toLowerCase();
				var breakingChangeType = this.getBreakingChangeType(cmdletName);
				const startPos = activeEditor.document.positionAt(match.index);
				const endPos = activeEditor.document.positionAt(match.index + match[0].length);
				const range = new vscode.Range(startPos, endPos);

				const diagnostic = new vscode.Diagnostic(range, "", vscode.DiagnosticSeverity.Information);

				switch (breakingChangeType) {
					case CMDLET_RENAME: {
						diagnostic.message = "This cmdlet change its name.";
						diagnostic.severity = 1;
						break;
					}
					case PARAMETER_CHANGE: {
						diagnostic.message = "This cmdlet has parameter changes.";
						diagnostic.severity = 1;
						break;
					}
					case DEPRECATED_CMDLET: {
						diagnostic.message = "This is a deprecated cmdlet.";
						diagnostic.severity = 0;
						break;
					}
					case CORRECT_CMDLET: {
						continue;
					}
				}

				diagnostic.code = breakingChangeType;
				diagnostics.push(diagnostic);
			}
		}
		this.breakingChangeDiagnostics.set(doc.uri, diagnostics);
	}

	getBreakingChangeType(cmdletName: string) {
		cmdletName = cmdletName.toLowerCase();
		if (cmdletName === "new-azurermkeyvault") {
			return PARAMETER_CHANGE;
		}
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
}