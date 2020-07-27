"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.displayUnderline = void 0;
const vscode = require("vscode");
// this method is called when vs code is activated
function displayUnderline(context, map) {
    return __awaiter(this, void 0, void 0, function* () {
        console.log('decorator sample is activated');
        let timeout = undefined;
        const AzureRMDecorationType = vscode.window.createTextEditorDecorationType({
            textDecoration: 'green wavy underline'
        });
        let activeEditor = vscode.window.activeTextEditor;
        function updateDecorations() {
            if (!activeEditor) {
                return;
            }
            const text = activeEditor.document.getText();
            const AzureRMCmdlet = [];
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
    });
}
exports.displayUnderline = displayUnderline;
//# sourceMappingURL=displayUnderline.js.map