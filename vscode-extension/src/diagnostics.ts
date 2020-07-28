import * as vscode from 'vscode';
import { loadAliasMapping } from './aliasMapping';

export const BREAKING_CHANGE = 'breaking_change';

export function refreshDiagnostics(doc: vscode.TextDocument, breakingChangeDiagnostics: vscode.DiagnosticCollection): void {
	const diagnostics: vscode.Diagnostic[] = [];

    var aliasMapping = loadAliasMapping();

	//for (let lineIndex = 0; lineIndex < doc.lineCount; lineIndex++) {
        
        let activeEditor = vscode.window.activeTextEditor;
        if (activeEditor) {
            const text = activeEditor.document.getText();
            let match;
            let re = new RegExp(/[a-zA-z]+-[a-zA-z]+/g);
            while ((match = re.exec(text))) {
                if (aliasMapping.has(match[0].toString().toLowerCase())) {
                    const startPos = activeEditor.document.positionAt(match.index);
                    const endPos = activeEditor.document.positionAt(match.index + match[0].length);

                    const range = new vscode.Range(startPos, endPos);
                    const diagnostic = new vscode.Diagnostic(range, "This is a AzureRM cmdlet.",
                        vscode.DiagnosticSeverity.Information);
                    diagnostic.code = BREAKING_CHANGE;
                    diagnostic.severity = 1;
                    diagnostics.push(diagnostic);
                }
            }
        }
	//}

	breakingChangeDiagnostics.set(doc.uri, diagnostics);
}


export function subscribeToDocumentChanges(context: vscode.ExtensionContext, breakingChangeDiagnostics: vscode.DiagnosticCollection): void {
	if (vscode.window.activeTextEditor) {
		refreshDiagnostics(vscode.window.activeTextEditor.document, breakingChangeDiagnostics);
	}
	context.subscriptions.push(
		vscode.window.onDidChangeActiveTextEditor(editor => {
			if (editor) {
				refreshDiagnostics(editor.document, breakingChangeDiagnostics);
			}
		})
	);

	context.subscriptions.push(
		vscode.workspace.onDidChangeTextDocument(e => refreshDiagnostics(e.document, breakingChangeDiagnostics))
	);

	context.subscriptions.push(
		vscode.workspace.onDidCloseTextDocument(doc => breakingChangeDiagnostics.delete(doc.uri))
	);

}