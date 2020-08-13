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

export const GetDiagnosticRequestType =
    new RequestType<any, any, void, void>("powerShell/getDiagnostic");

export const DocumentSymbolType = new RequestType<any, any, void, void>("textDocument/documentSymbol")

export class GetDiagnosticFeature extends LanguageClientConsumer {

    breakingChangeDiagnostics = vscode.languages.createDiagnosticCollection("breaking change");
    
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

        /*var diagnosticsManagement=new DiagnosticsManagement(context);

        let disposable = vscode.commands.registerCommand('extension.helloWorld', async() => {
            var sourceVersion = await getSrcVersion();

            if (sourceVersion != undefined) {
                vscode.window.showInformationMessage(`Updating powershell scripts from '${sourceVersion}' to latest`);
                diagnosticsManagement.refreshMapping(context,sourceVersion);
            }
        })

        context.subscriptions.push(disposable);*/
    }

    public dispose() {
    }

    private sendRequestToServer() {
        let activeEditor = vscode.window.activeTextEditor;
        let content = "";
        if (activeEditor) {
            content = activeEditor.document.getText();
        }
        this.languageClient.sendRequest(GetDiagnosticRequestType, {
            Content: content
        }).then(
            (data) => {
                let doc = vscode.window.activeTextEditor.document;
                this.breakingChangeDiagnostics.set(doc.uri, data.diagnostics);
            }
        );
    }
}
