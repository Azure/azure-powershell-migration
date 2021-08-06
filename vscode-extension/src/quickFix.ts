/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import * as vscode from 'vscode';

export const BREAKING_CHANGE = 'breaking change';
export const DEPRECATED_CMDLET = 'deprecated cmdlet';
export const CMDLET_RENAME = 'cmdlet rename';
export const PARAMETER_CHANGE = 'parameter change';
export const DO_NOTHING = 'do nothing';

export const GET_INFO_COMMAND = 'getInfo';
export const GET_DEPRE_INFO_COMMAND = 'getdepreInfo';

export class BreakingChangeInfo implements vscode.CodeActionProvider {

	constructor() { }

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] | any[] {
		let autoFixCodeAction = context.diagnostics
			.map(diagnostic => this.getAutoFixCodeAction(diagnostic));

		return autoFixCodeAction;
	}

	private getAutoFixCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction | undefined {
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
		let targetCmdletName = String(diagnostic.source);

		switch (diagnostic.code) {
			case "RENAME": {
				fix.title = "Auto fix to " + targetCmdletName;
				fix.edit.replace(document.uri, range, targetCmdletName);
				break;
			}
			case "DO_NOTHING": {
				return undefined;
			}
		}

		return fix;
	}
}