import * as vscode from 'vscode';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
import { GET_INFO_COMMAND, GET_DEPRE_INFO_COMMAND,DEPRECATED_CMDLET, CMDLET_RENAME, DO_NOTHING, PARAMETER_CHANGE, BreakingChangeInfo } from './quickFix';

export class DiagnosticsManagement {
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();
	aliasMapping: Map<string, string> = new Map();
	breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	breakingChangeInfo = new BreakingChangeInfo();
	
	severityMap = new Map([
        [CMDLET_RENAME, vscode.DiagnosticSeverity.Warning],
		[PARAMETER_CHANGE, vscode.DiagnosticSeverity.Warning],
		[DEPRECATED_CMDLET, vscode.DiagnosticSeverity.Error]
    ]);

	constructor(context: vscode.ExtensionContext) {
		// Register new action
		context.subscriptions.push(this.breakingChangeDiagnostics);

		// register OnDidChange action
		context.subscriptions.push(
			vscode.window.onDidChangeActiveTextEditor(editor => {
				if (editor) {
					this.refreshTextEditorHelper(editor.document);
				}
			}),
			vscode.workspace.onDidChangeTextDocument(e => this.refreshTextEditorHelper(e.document)),
			vscode.workspace.onDidCloseTextDocument(doc => this.breakingChangeDiagnostics.delete(doc.uri))
		);

		// register CodeActionProvider
		context.subscriptions.push(
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.breakingChangeInfo , {
				providedCodeActionKinds: BreakingChangeInfo.providedCodeActionKinds
			})
		);

		// register Command
		context.subscriptions.push(
			vscode.commands.registerCommand(GET_INFO_COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/module'))),
			vscode.commands.registerCommand(GET_DEPRE_INFO_COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/azure/migrate-az-1.0.0')))
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
		this.breakingChangeInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);

		if (vscode.window.activeTextEditor) {
			this.refreshTextEditorHelper(vscode.window.activeTextEditor.document);
		}		
	}

	refreshTextEditorHelper(doc: vscode.TextDocument): void {
		let diagnostics: vscode.Diagnostic[] = [];

		let activeEditor = vscode.window.activeTextEditor;
		if (activeEditor) {
			let text = activeEditor.document.getText();
			let re = new RegExp(/[a-zA-z]+-[a-zA-z]+/g);
			let match = null;
			while ((match = re.exec(text))) {
				let sourceCmdletName = match[0].toString();
				let breakingChangeType = this.getBreakingChangeType(sourceCmdletName);
				let startPos = activeEditor.document.positionAt(match.index);
				let endPos = activeEditor.document.positionAt(match.index + match[0].length);
				let range = new vscode.Range(startPos, endPos);
				if (breakingChangeType === DO_NOTHING || this.isCommentLine(range)) {
					continue;
				}

				let diagnostic = new vscode.Diagnostic(range, "", vscode.DiagnosticSeverity.Information);
				diagnostic.message = this.getDiagnosticMessage(breakingChangeType, sourceCmdletName);
				diagnostic.severity = this.severityMap.get(breakingChangeType)!;
				diagnostic.code = breakingChangeType;
				diagnostics.push(diagnostic);
			}
		}
		this.breakingChangeDiagnostics.set(doc.uri, diagnostics);
	}

	// judge whether or not comment line
	isCommentLine(range: vscode.Range) {
		let activeEditor = vscode.window.activeTextEditor;
		if (activeEditor) {
			let lineNumber = range.start.line;
			let line = activeEditor.document.lineAt(lineNumber);
			let lineText = line.text;
			if (lineText.toString().trim().startsWith('#')) {
				return true;
			}
		}
		return false;
	}

	getBreakingChangeType(sourceCmdletName: string) {
		let sourceCmdletNameLowerCase = sourceCmdletName.toLowerCase();
		// hardcode
		if (sourceCmdletNameLowerCase === "new-azurermkeyvault") {
			return PARAMETER_CHANGE;
		}
		// if find cmlet in sourceCmdlet
		if (this.sourceCmdlets.has(sourceCmdletNameLowerCase)) {
			let targetCmdletNameLowerCase = this.aliasMapping.get(sourceCmdletNameLowerCase)!.toLowerCase();
			if (this.aliasMapping.has(sourceCmdletNameLowerCase) && this.targetCmdlets.has(targetCmdletNameLowerCase)) {
				return CMDLET_RENAME;
			} else {
				return DEPRECATED_CMDLET;
			}
		}
		return DO_NOTHING;
	}

	getDiagnosticMessage(breakingChangeType: string, sourceCmdletName: string) {
		let sourceCmdletNameLowerCase = sourceCmdletName.toLowerCase();
		let targetCmdletName = this.aliasMapping.get(sourceCmdletNameLowerCase)!;
		let targetCmdletNameLowerCase = targetCmdletName.toLowerCase();
		let message = "";

		switch (breakingChangeType) {
			case CMDLET_RENAME: {
				let sourceCmdletModule:string = this.sourceCmdlets.get(sourceCmdletNameLowerCase).SourceModule.toLowerCase();
				let targeCmdletModule:string = this.targetCmdlets.get(targetCmdletNameLowerCase).SourceModule.toLowerCase();

				message =
					sourceCmdletName + " changes to " + targetCmdletName + "." +
					"\nSourceCmdlet info: https://docs.microsoft.com/en-us/powershell/module/" + sourceCmdletModule + "/" + sourceCmdletName +
					"\nTargetCmdlet info: https://docs.microsoft.com/en-us/powershell/module/" + targeCmdletModule + "/" + targetCmdletName + "\n";
				break;
			}
			case PARAMETER_CHANGE: {
				let sourceCmdletModule:string = this.sourceCmdlets.get(sourceCmdletNameLowerCase).SourceModule.toLowerCase();
				let targeCmdletModule:string = this.targetCmdlets.get(targetCmdletNameLowerCase).SourceModule.toLowerCase();

				let detailsInfo = sourceCmdletName + "'s parameters changed during migration.";
				// hard code
				if (sourceCmdletNameLowerCase === 'new-azurermkeyvault') {
					detailsInfo +=
						"\nDisableSoftDelete is true by default for " + sourceCmdletName + 
						" but EnableSoftDelete is true by default for " + targetCmdletName + ".";
				}
				let cmdletInfo =
					"\nSourceCmdlet info: https://docs.microsoft.com/en-us/powershell/module/" + sourceCmdletModule + "/" + sourceCmdletName +
					"\nTargetCmdlet info: https://docs.microsoft.com/en-us/powershell/module/" + targeCmdletModule + "/" + targetCmdletName + "\n";

				message = detailsInfo + cmdletInfo;
				
				break;
			}
			case DEPRECATED_CMDLET: {				
				message = 
					sourceCmdletName + " is a deprecated cmdlet." +
					"\nSee more inforamtion: https://docs.microsoft.com/en-us/powershell/azure/migrate-az-1.0.0\n";		
				break;
			}
		}
		return message;
	}
}