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

export const GetAstRequestType =
    new RequestType<any, any, void, void>("powerShell/getAst");

export const DocumentSymbolType = new RequestType<any, any, void, void>("textDocument/documentSymbol")

enum SearchState { Searching, Locked, Found }

export class GetAstFeature extends LanguageClientConsumer {

    constructor(private log: Logger, context: vscode.ExtensionContext) {
        super();
        let disposable = vscode.commands.registerCommand('extension.helloWorld', () => {
            // The code you place here will be executed every time your command is executed
    
            // Display a message box to the user
            vscode.window.showInformationMessage('Hello World from abc!');
            this.languageClient.sendRequest(GetAstRequestType, {
                Content: "Get-Item"
            }).then(
                (data) => {
                    console.debug("GetAst result:", data);
                }
            );
        });
    
        context.subscriptions.push(disposable);
    }

    public dispose() {
    }

    public setLanguageClient(languageClient: LanguageClient) {
        this.languageClient = languageClient;
        // this.languageClient.sendRequest(DocumentSymbolType, {

        // })
    }

    public async onEvent(changeEvent: TextDocumentChangeEvent): Promise<void> {
        // if (!(changeEvent && changeEvent.contentChanges)) {
        //     this.log.writeWarning(`<${HelpCompletionFeature.name}>: ` +
        //         `Bad TextDocumentChangeEvent message: ${JSON.stringify(changeEvent)}`);
        //     return;
        // }

        // if (changeEvent.contentChanges.length > 0) {
        //     this.helpCompletionProvider.updateState(
        //         changeEvent.document,
        //         changeEvent.contentChanges[0].text,
        //         changeEvent.contentChanges[0].range);

        //     // todo raise an event when trigger is found, and attach complete() to the event.
        //     if (this.helpCompletionProvider.triggerFound) {
        //         await this.helpCompletionProvider.complete();
        //         await this.helpCompletionProvider.reset();
        //     }
        // }
    }
}
