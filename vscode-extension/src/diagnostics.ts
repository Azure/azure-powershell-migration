import * as vscode from 'vscode';

export const BREAKING_CHANGE = 'breaking change';
export const DEPRECATED_CMDLET = 'depracated cmdlet';
export const CMDLET_RENAME = 'cmdlet rename';

export function refreshDiagnostics(doc: vscode.TextDocument, breakingChangeDiagnostics: vscode.DiagnosticCollection, aliasMapping: Map<string, string>, sourceCmdlets: Map<string, any>, targetCmdlets: Map<string, any>): void {
	const diagnostics: vscode.Diagnostic[] = [];

 	let activeEditor = vscode.window.activeTextEditor;
	if (activeEditor) {
        const text = activeEditor.document.getText();
        let match;
        let re = new RegExp(/[a-zA-z]+-[a-zA-z]+/g);
		while ((match = re.exec(text))) {
			var cmdletName = match[0].toString().toLowerCase();
			var resolvedName = aliasMapping.get(cmdletName)?.toLowerCase();
			const startPos = activeEditor.document.positionAt(match.index);
			const endPos = activeEditor.document.positionAt(match.index + match[0].length);
			const range = new vscode.Range(startPos, endPos);
			
			if (aliasMapping.has(cmdletName) && resolvedName && targetCmdlets.has(resolvedName)) {
				const diagnostic = new vscode.Diagnostic(range, "This cmdlet change its name.",
					vscode.DiagnosticSeverity.Information);
				diagnostic.code = CMDLET_RENAME;
				diagnostic.severity = 1;
				diagnostics.push(diagnostic);
			} else if (sourceCmdlets.has(cmdletName)) {
				const diagnostic = new vscode.Diagnostic(range, "This is a deprecated cmdlet.",
				vscode.DiagnosticSeverity.Information);
				diagnostic.code = DEPRECATED_CMDLET;
				diagnostic.severity = 0;
				diagnostics.push(diagnostic);
			}
		}
	}
	breakingChangeDiagnostics.set(doc.uri, diagnostics);
}

export function subscribeToDocumentChanges(context: vscode.ExtensionContext, breakingChangeDiagnostics: vscode.DiagnosticCollection, aliasMapping: Map<string, string>, sourceCmdlets: Map<string, any>, targetCmdlets: Map<string, any>): void {
	if (vscode.window.activeTextEditor) {
		refreshDiagnostics(vscode.window.activeTextEditor.document, breakingChangeDiagnostics, aliasMapping, sourceCmdlets, targetCmdlets);
	}
	context.subscriptions.push(
		vscode.window.onDidChangeActiveTextEditor(editor => {
			if (editor) {
				refreshDiagnostics(editor.document, breakingChangeDiagnostics, aliasMapping, sourceCmdlets, targetCmdlets);
			}
		})
	);

	context.subscriptions.push(
		vscode.workspace.onDidChangeTextDocument(e => refreshDiagnostics(e.document, breakingChangeDiagnostics, aliasMapping, sourceCmdlets, targetCmdlets))
	);

	context.subscriptions.push(
		vscode.workspace.onDidCloseTextDocument(doc => breakingChangeDiagnostics.delete(doc.uri))
	);

}