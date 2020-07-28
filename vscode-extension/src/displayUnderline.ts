import * as vscode from 'vscode';

// this method is called when vs code is activated
export async function displayUnderline(context: vscode.ExtensionContext, sourceCmdlets: Map<string, any>, targetCmdlets: Map<string, any>, aliasMapping: Map<string, string>) {

	let timeout: NodeJS.Timer | undefined = undefined;

	const AzureRMDecorationType = vscode.window.createTextEditorDecorationType({
		textDecoration: 'wavy underline #FFBF00',
		overviewRulerColor: new vscode.ThemeColor('editorWarning.foreground'),
		borderColor: new vscode.ThemeColor('editorWarning.foreground'),
		rangeBehavior: vscode.DecorationRangeBehavior.OpenOpen
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
			if (aliasMapping.has(match[0].toString().toLowerCase())) {
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