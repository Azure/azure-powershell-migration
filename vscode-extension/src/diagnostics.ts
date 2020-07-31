import * as vscode from 'vscode';
import { loadSrcVersionCmdletSpec, loadLatestVersionCmdletSpec, loadAliasMapping } from './aliasMapping';
//import { GET_INFO_COMMAND,GET_DEPRE_INFO_COMMAND,DEPRECATED_CMDLET, CMDLET_RENAME, CORRECT_CMDLET, CmdletRenameInfo, DeprecatedCmdletInfo,PARAMETER_CHANGE,ParameterChangeInfo, BreakingChangeInfo } from './quickFix';
import { GET_INFO_COMMAND, GET_DEPRE_INFO_COMMAND,DEPRECATED_CMDLET, CMDLET_RENAME, DO_NOTHING, PARAMETER_CHANGE, BreakingChangeInfo } from './quickFix';

export class DiagnosticsManagement {
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();
	aliasMapping: Map<string, string> = new Map();
	breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
	/*cmdletRenameInfo = new CmdletRenameInfo();
	deprecatedCmdletInfo=new DeprecatedCmdletInfo();
	parameterChangeInfo = new ParameterChangeInfo();*/
	breakingChangeInfo = new BreakingChangeInfo();

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
			/*vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.cmdletRenameInfo , {
				providedCodeActionKinds: CmdletRenameInfo.providedCodeActionKinds
			}),
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.deprecatedCmdletInfo, {
				providedCodeActionKinds: DeprecatedCmdletInfo.providedCodeActionKinds
			}),
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.parameterChangeInfo , {
				providedCodeActionKinds: ParameterChangeInfo.providedCodeActionKinds
			})*/
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.breakingChangeInfo , {
				providedCodeActionKinds: BreakingChangeInfo.providedCodeActionKinds
			})
		);

		context.subscriptions.push(
			vscode.commands.registerCommand(GET_INFO_COMMAND, () => vscode.env.openExternal(vscode.Uri.parse('https://docs.microsoft.com/en-us/powershell/module')))
		);
		context.subscriptions.push(
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
		/*this.cmdletRenameInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);
		this.deprecatedCmdletInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);
		this.parameterChangeInfo.updateMapping(this.sourceCmdlets, this.targetCmdlets, this.aliasMapping);*/
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
				let lowerCaseSrcCmdletName = sourceCmdletName.toLowerCase();
				let breakingChangeType = this.getBreakingChangeType(lowerCaseSrcCmdletName);

				let startPos = activeEditor.document.positionAt(match.index);
				let endPos = activeEditor.document.positionAt(match.index + match[0].length);
				let range = new vscode.Range(startPos, endPos);

				// skip comments
				let lineNumber = range.start.line;
				let line = activeEditor.document.lineAt(lineNumber);
				let lineText = line.text;
				if (lineText.toString().trim().startsWith('#')) {
					continue;
				}

				let diagnostic = new vscode.Diagnostic(range, "", vscode.DiagnosticSeverity.Information);

				switch (breakingChangeType) {
					case CMDLET_RENAME: {
						var targetCmdletName=this.aliasMapping.get(lowerCaseSrcCmdletName)!.toString();
						var sourceCmdletModule:string=this.sourceCmdlets.get(lowerCaseSrcCmdletName).SourceModule.toLowerCase();
						var targeCmdletModule:string=this.targetCmdlets.get(targetCmdletName.toLowerCase()).SourceModule.toLowerCase();					
						diagnostic.message = sourceCmdletName+" changes to "+targetCmdletName+"."+
							"\nSourceCmdlet info: https://docs.microsoft.com/en-us/powershell/module/"+sourceCmdletModule+"/"+sourceCmdletName+
							"\nTargetCmdlet info: https://docs.microsoft.com/en-us/powershell/module/"+targeCmdletModule.toLowerCase()+"/"+targetCmdletName+"\n";
						diagnostic.severity = 1;
						break;
					}
					case PARAMETER_CHANGE: {
						var targetCmdletName=this.aliasMapping.get(lowerCaseSrcCmdletName)!.toString();
						var sourceCmdletModule:string=this.sourceCmdlets.get(lowerCaseSrcCmdletName).SourceModule.toLowerCase();
						var targeCmdletModule:string=this.targetCmdlets.get(targetCmdletName.toLowerCase()).SourceModule.toLowerCase();

						var detailsInfo=sourceCmdletName+"'s parameters changed during migration.";
						if (lowerCaseSrcCmdletName==='new-azurermkeyvault') {
							detailsInfo+="\nDisableSoftDelete is true by default for "+sourceCmdletName+" but EnableSoftDelete is true by default for "+targetCmdletName+".";
						}
						var cmdletInfo="\nSourceCmdlet info: https://docs.microsoft.com/en-us/powershell/module/"+sourceCmdletModule+"/"+sourceCmdletName+
							"\nTargetCmdlet info: https://docs.microsoft.com/en-us/powershell/module/"+targeCmdletModule.toLowerCase()+"/"+targetCmdletName+"\n";
							
						diagnostic.message = detailsInfo+cmdletInfo;
						
						diagnostic.severity = 1;
						break;
					}
					case DEPRECATED_CMDLET: {				
						diagnostic.message = sourceCmdletName+" is a deprecated cmdlet."+
							"\nSee more inforamtion: https://docs.microsoft.com/en-us/powershell/azure/migrate-az-1.0.0\n";		
						diagnostic.severity = 0;
						break;
					}
					case DO_NOTHING: {
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
		return DO_NOTHING;
	}
	
	getInfoUrl():string{
		return "";
	}
}