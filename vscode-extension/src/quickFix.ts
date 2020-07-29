import * as vscode from 'vscode';

export const BREAKING_CHANGE = 'breaking change';
export const DEPRECATED_CMDLET = 'depracated cmdlet';
export const CMDLET_RENAME = 'cmdlet rename';
export const PARAMETER_CHANGE = 'parameter change';
export const CORRECT_CMDLET = 'correct cmdlet';

export class CmdletRenameInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor(){}

	updateMapping(sourceCmdlets: Map<string, string>,targetCmdlets: Map<string, string>,aliasMapping: Map<string, string>){
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		return context.diagnostics
			.filter(diagnostic => diagnostic.code === CMDLET_RENAME)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
	}

	private createCommandCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Auto Fix to `, vscode.CodeActionKind.QuickFix);
		var range = diagnostic.range;
		fix.edit = new vscode.WorkspaceEdit();
		var editor = vscode.window.activeTextEditor;
		if (editor) {
			var document = editor.document;
			var text = document.getText(range);
			var replace = this.aliasMapping.get(text.toLowerCase())!;
			fix.title += replace;
			fix.edit.replace(document.uri, range, replace);
		}
		return fix;
	}
}

export class DepracatedCmdletInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor(){}

	updateMapping(sourceCmdlets: Map<string, string>,targetCmdlets: Map<string, string>,aliasMapping: Map<string, string>){
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}
	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		return context.diagnostics
			.filter(diagnostic => diagnostic.code === DEPRECATED_CMDLET)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
	}

	private createCommandCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Delete this line`, vscode.CodeActionKind.QuickFix);
		fix.edit = new vscode.WorkspaceEdit();
		var editor = vscode.window.activeTextEditor;
		if (editor) {
			var lineNumber = diagnostic.range.start.line;
			var line = editor.document.lineAt(lineNumber);
			var range;
			if (lineNumber === 0) {
				if (editor.document.lineCount === 1) {
					range = new vscode.Range(line.range.start, line.range.end);
				} else {
					var nextLine = editor.document.lineAt(diagnostic.range.start.line + 1);
					range = new vscode.Range(line.range.start, nextLine.range.start);
				}
			} else {
				var preLine = editor.document.lineAt(diagnostic.range.start.line - 1);
				range = new vscode.Range(preLine.range.end, line.range.end);
			}
			var document = editor.document;
			fix.edit.replace(document.uri, range, "");
		}
		return fix;
	}
}

export class ParameterChangeInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor(){}

	updateMapping(sourceCmdlets: Map<string, string>,targetCmdlets: Map<string, string>,aliasMapping: Map<string, string>){
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}
	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		return context.diagnostics
			.filter(diagnostic => diagnostic.code === PARAMETER_CHANGE)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
	}

	private createCommandCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Auto Fix to `, vscode.CodeActionKind.QuickFix);
		var range = diagnostic.range;
		fix.edit = new vscode.WorkspaceEdit();
		var editor = vscode.window.activeTextEditor;
		if (editor) {
			var document = editor.document;
			var text = document.getText(range);
			var replace = this.aliasMapping.get(text.toLowerCase())!;
			fix.title += replace;
			fix.edit.replace(document.uri, range, replace);

			var lineNumber = diagnostic.range.start.line;
			var line = editor.document.lineAt(lineNumber);
			var newCmdlet = line.text;
			if (newCmdlet.match(".*-EnableSoftDelete.*")) {
				newCmdlet = newCmdlet.replace(" -EnableSoftDelete", "");
			} else {
				newCmdlet = newCmdlet + " -DisableSoftDelete";
			}
			var range = new vscode.Range(line.range.start, line.range.end);
			var document = editor.document;
			fix.edit.replace(document.uri, range, newCmdlet);
		}
		return fix;
	}
}