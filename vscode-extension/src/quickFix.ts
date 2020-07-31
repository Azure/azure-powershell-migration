import * as vscode from 'vscode';

export const BREAKING_CHANGE = 'breaking change';
export const DEPRECATED_CMDLET = 'deprecated cmdlet';
export const CMDLET_RENAME = 'cmdlet rename';
export const PARAMETER_CHANGE = 'parameter change';
export const DO_NOTHING = 'do nothing';

export const GET_INFO_COMMAND = 'getInfo';
export const GET_DEPRE_INFO_COMMAND = 'getdepreInfo';

export class BreakingChangeInfo implements vscode.CodeActionProvider {
	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor() { }

	updateMapping(sourceCmdlets: Map<string, string>, targetCmdlets: Map<string, string>, aliasMapping: Map<string, string>) {
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		let autoFixCodeAction = context.diagnostics
			.map(diagnostic => this.getAutoFixCodeAction(diagnostic));

		// Add action to get more info
		let infoCodeAction = context.diagnostics
			.map(diagnostic => this.getInfoCodeAction(diagnostic));

		let actions = autoFixCodeAction.concat(infoCodeAction);

		return actions;
	}

	private getAutoFixCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		let fix = new vscode.CodeAction("", vscode.CodeActionKind.QuickFix);
		fix.edit = new vscode.WorkspaceEdit();
		let editor = vscode.window.activeTextEditor;
		
		if (!editor) {
			return fix;
		}

		let document = editor.document;
		let range = diagnostic.range;
		let lineNumber = range.start.line;
		let line = editor.document.lineAt(lineNumber);
		let rangeLine = new vscode.Range(line.range.start, line.range.end);
		let sourceCmdletName = document.getText(range);
		let targetCmdletName = this.aliasMapping.get(sourceCmdletName.toLowerCase())!;

		switch (diagnostic.code) {
			case CMDLET_RENAME: {
				fix.title = "Auto fix to " + targetCmdletName;
				fix.edit.replace(document.uri, range, targetCmdletName);
				break;
			}
			case DEPRECATED_CMDLET: {
				fix.title = "Comment out this line";
				let newLine = "# " + line.text;
				fix.edit.replace(document.uri, rangeLine, newLine);
				break;
			}
			case PARAMETER_CHANGE: {
				fix.title = "Auto fix to " + targetCmdletName;
				fix.edit.replace(document.uri, range, targetCmdletName);
		
				let newLine = line.text;
				if (newLine.match(".*-EnableSoftDelete.*")) {
					newLine = newLine.replace(" -EnableSoftDelete", "");
				} else {
					newLine = newLine + " -DisableSoftDelete";
				}
				newLine = newLine.replace("-VaultName", "-Name");
				fix.edit.replace(document.uri, rangeLine, newLine);
				break;
			}
		}

		return fix;
	}

	private getInfoCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		let action = new vscode.CodeAction('Learn more...', vscode.CodeActionKind.QuickFix);
		switch (diagnostic.code) {
			case CMDLET_RENAME: {
				action.command = { command: GET_INFO_COMMAND, title: 'Learn more ...'};
				break;
			}
			case DEPRECATED_CMDLET: {
				action.command = { command: GET_DEPRE_INFO_COMMAND, title: 'Learn more ...' };
				break;
			}
			case PARAMETER_CHANGE: {
				action.command = { command: GET_DEPRE_INFO_COMMAND, title: 'Learn more ...' };
				break;
			}
		}
		return action;
	}

	getInfo() {
		
	}
}

/*
export class CmdletRenameInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor() { }

	updateMapping(sourceCmdlets: Map<string, string>, targetCmdlets: Map<string, string>, aliasMapping: Map<string, string>) {
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		var renameCmdlet = context.diagnostics
			.filter(diagnostic => diagnostic.code === CMDLET_RENAME)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
		// Add action to get more info
		const getInfo = context.diagnostics
			.filter(diagnostic => diagnostic.code === CMDLET_RENAME)
			.map(diagnostic => this.getInfo());
		const actions = renameCmdlet.concat(getInfo);

		return actions;
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

	private getInfo(): vscode.CodeAction {
		const action = new vscode.CodeAction('Learn more...', vscode.CodeActionKind.QuickFix);
		action.command = { command: GET_INFO_COMMAND, title: 'Learn more ...' };

		return action;
	}
}

export class DeprecatedCmdletInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor() { }

	updateMapping(sourceCmdlets: Map<string, string>, targetCmdlets: Map<string, string>, aliasMapping: Map<string, string>) {
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}
	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		var deleteCmdlet = context.diagnostics
			.filter(diagnostic => diagnostic.code === DEPRECATED_CMDLET)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));

		// Add action to get more info
		const getDeprecatedInfo = context.diagnostics
			.filter(diagnostic => diagnostic.code === DEPRECATED_CMDLET)
			.map(diagnostic => this.getDeprecatedInfo());
		const actions = deleteCmdlet.concat(getDeprecatedInfo);

		return actions;
	}

	private createCommandCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Comment out this line`, vscode.CodeActionKind.QuickFix);
		fix.edit = new vscode.WorkspaceEdit();
		var editor = vscode.window.activeTextEditor;
		if (editor) {
			var lineNumber = diagnostic.range.start.line;
			var line = editor.document.lineAt(lineNumber);
			var newCmdlet = "# " + line.text;
			var range = new vscode.Range(line.range.start, line.range.end);
			var document = editor.document;
			fix.edit.replace(document.uri, range, newCmdlet);
		}
		return fix;
	}
	private getDeprecatedInfo(): vscode.CodeAction {
		const action = new vscode.CodeAction('Learn more...', vscode.CodeActionKind.QuickFix);
		action.command = { command: GET_DEPRE_INFO_COMMAND, title: 'Learn more ...' };

		return action;
	}
}

export class ParameterChangeInfo implements vscode.CodeActionProvider {

	aliasMapping: Map<string, string> = new Map();
	sourceCmdlets: Map<string, any> = new Map();
	targetCmdlets: Map<string, any> = new Map();

	constructor() { }

	updateMapping(sourceCmdlets: Map<string, string>, targetCmdlets: Map<string, string>, aliasMapping: Map<string, string>) {
		this.sourceCmdlets = sourceCmdlets;
		this.targetCmdlets = targetCmdlets;
		this.aliasMapping = aliasMapping;
	}
	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		var changeCmdlet = context.diagnostics
			.filter(diagnostic => diagnostic.code === PARAMETER_CHANGE)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
		var getDeprecatedInfo = context.diagnostics
			.filter(diagnostic => diagnostic.code === PARAMETER_CHANGE)
			.map(diagnostic => this.getDeprecatedInfo());
		const actions = changeCmdlet.concat(getDeprecatedInfo);
		return actions;

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
			newCmdlet = newCmdlet.replace("-VaultName", "-Name");
			var range = new vscode.Range(line.range.start, line.range.end);
			var document = editor.document;
			fix.edit.replace(document.uri, range, newCmdlet);
		}
		return fix;
	}

	private getDeprecatedInfo(): vscode.CodeAction {
		const action = new vscode.CodeAction('Learn more...', vscode.CodeActionKind.QuickFix);
		action.command = { command: GET_DEPRE_INFO_COMMAND, title: 'Learn more ...' };

		return action;
	}
}
*/