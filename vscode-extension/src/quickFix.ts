import * as vscode from 'vscode';
import { loadAliasMapping } from './aliasMapping';
import { BREAKING_CHANGE } from './diagnostics';

export const COMMAND = 'quickfix.command';

export class QuickFixer implements vscode.CodeActionProvider {

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	public provideCodeActions(document: vscode.TextDocument, range: vscode.Range): vscode.CodeAction[] | undefined {
		const codeActions = [];
		const editor = vscode.window.activeTextEditor;

		const text = document.getText(editor?.selection).toString();
		
		var aliasMap = loadAliasMapping();

		if (aliasMap.has(text.toLowerCase())) {
			var replace = aliasMap.get(text.toLowerCase())!;
			const replaceWithAz = this.createFix(document, range, replace);
			replaceWithAz.isPreferred = true;

			codeActions.push(replaceWithAz);
		}
		return codeActions;
	}

	private createFix(document: vscode.TextDocument, range: vscode.Range, replace: string): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Auto migration to Az`, vscode.CodeActionKind.QuickFix);
		fix.edit = new vscode.WorkspaceEdit();
		fix.edit.replace(document.uri, new vscode.Range(range.start, range.end), replace);
		return fix;
	}
}

export class QuickFixinfo implements vscode.CodeActionProvider {

	public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
	];

	provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		// for each diagnostic entry that has the matching `code`, create a code action command
		return context.diagnostics
			.filter(diagnostic => diagnostic.code === BREAKING_CHANGE)
			.map(diagnostic => this.createCommandCodeAction(diagnostic));
	}

	private createCommandCodeAction(diagnostic: vscode.Diagnostic): vscode.CodeAction {
		const fix = new vscode.CodeAction(`Auto Fix`, vscode.CodeActionKind.QuickFix);
		var range = diagnostic.range;
		fix.edit = new vscode.WorkspaceEdit();
		var editor = vscode.window.activeTextEditor;
		if (editor) {
			var document = editor.document;
			var text = document.getText(range);
			var aliasMapping = loadAliasMapping();
			var replace = aliasMapping.get(text.toLowerCase())!;
			fix.edit.replace(document.uri, new vscode.Range(range.start, range.end), replace);
		}
		return fix;
	}
}