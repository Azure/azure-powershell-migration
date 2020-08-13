/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import { Disposable, EndOfLine, Position, Range, SnippetString,
    TextDocument, TextDocumentChangeEvent, window, workspace } from "vscode";
import { LanguageClient, RequestType } from "vscode-languageclient";
import { Logger } from "../logging";
import Settings = require("../settings");
import vscode = require("vscode");
import { LanguageClientConsumer } from "../languageClientConsumer";
import { getSrcVersion } from "../selectVersion";

export const GetCodeActionRequestType =
    new RequestType<any, any, void, void>("powerShell/getCodeAction");

export const DocumentSymbolType = new RequestType<any, any, void, void>("textDocument/documentSymbol")

export class GetCodeActionFeature extends LanguageClientConsumer {

    breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
    migrateInfo = new MigrateCodeActionProvider();

    constructor(private log: Logger, context: vscode.ExtensionContext) {
        super();
        let disposable = vscode.commands.registerCommand('azure-powershell-migration.selectVersion', async () => {
            var sourceVersion = await getSrcVersion();
            vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
            this.sendRequestToServer();
        });
    
        context.subscriptions.push(disposable);

        context.subscriptions.push(
			vscode.window.onDidChangeActiveTextEditor(editor => {
				if (editor) {
					this.sendRequestToServer();
				}
			}),
			vscode.workspace.onDidChangeTextDocument(e => this.sendRequestToServer()),
			vscode.workspace.onDidCloseTextDocument(doc => this.breakingChangeDiagnostics.delete(doc.uri))
        );
        
        context.subscriptions.push(
			vscode.languages.registerCodeActionsProvider({ language: 'powershell' }, this.migrateInfo , {
				providedCodeActionKinds: MigrateCodeActionProvider.providedCodeActionKinds
			})
		);
    }

    public dispose() {
    }

    private sendRequestToServer() {
        let activeEditor = vscode.window.activeTextEditor;
        let content = "";
        if (activeEditor) {
            content = activeEditor.document.getText();
        }
        this.languageClient.sendRequest(GetCodeActionRequestType, {
            Content: content
        }).then(
            (data) => {
                let doc = vscode.window.activeTextEditor.document;
                this.breakingChangeDiagnostics.set(doc.uri, data.diagnostics);
            }
        );
    }
}

export class MigrateCodeActionProvider implements vscode.CodeActionProvider {
    
    constructor() { }

    public static readonly providedCodeActionKinds = [
		vscode.CodeActionKind.QuickFix
    ];
    
    provideCodeActions(document: vscode.TextDocument, range: vscode.Range | vscode.Selection, context: vscode.CodeActionContext, token: vscode.CancellationToken): vscode.CodeAction[] {
		let autoFixCodeAction = context.diagnostics
			.map(diagnostic => this.getAutoFixCodeAction(diagnostic));

		return autoFixCodeAction;
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
        
        fix.title = "Auto fix";
        fix.edit.replace(document.uri, range, "test");

        return fix;
    }
} 