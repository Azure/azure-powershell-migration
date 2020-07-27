import * as vscode from 'vscode';

// this method is called when vs code is activated
export async function displayUnderline(context: vscode.ExtensionContext, map: Map<string, string>) {

	console.log('decorator sample is activated');

	let timeout: NodeJS.Timer | undefined = undefined;

	const AzureRMDecorationType = vscode.window.createTextEditorDecorationType({
		textDecoration: 'green wavy underline'
	});

	let activeEditor = vscode.window.activeTextEditor;

	function updateDecorations() {
		if (!activeEditor) {
			return;
		}
		const text = activeEditor.document.getText();
		const AzureRMCmdlet: vscode.DecorationOptions[] = [];
		let match;
		
		let re = new RegExp(/[a-zA-z]+-[a-zA-z]+/g);
		while ((match = re.exec(text))) {
			if (map.has(match.toString())) {
				const startPos = activeEditor.document.positionAt(match.index);
				const endPos = activeEditor.document.positionAt(match.index + match[0].length);
				const decoration = { range: new vscode.Range(startPos, endPos), hoverMessage: 'AzureRM' };
				AzureRMCmdlet.push(decoration);
			}
		}
		activeEditor.setDecorations(AzureRMDecorationType, AzureRMCmdlet);
	}

	function triggerUpdateDecorations() {
		if (timeout) {
			clearTimeout(timeout);
			timeout = undefined;
		}
		timeout = setTimeout(updateDecorations, 50);
	}

	if (activeEditor) {
		triggerUpdateDecorations();
	}

	vscode.window.onDidChangeActiveTextEditor(editor => {
		activeEditor = editor;
		if (editor) {
			triggerUpdateDecorations();
		}
	}, null, context.subscriptions);

	vscode.workspace.onDidChangeTextDocument(event => {
		if (activeEditor && event.document === activeEditor.document) {
			triggerUpdateDecorations();
		}
	}, null, context.subscriptions);

}