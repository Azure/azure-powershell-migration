import * as vscode from 'vscode';
import { loadAliasMapping } from './aliasMapping';

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