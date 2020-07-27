"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
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
exports.multiStepInput = void 0;
const vscode_1 = require("vscode");
class InputFlowAction {
}
InputFlowAction.back = new InputFlowAction();
InputFlowAction.cancel = new InputFlowAction();
InputFlowAction.resume = new InputFlowAction();
class MultiStepInput {
    constructor() {
        this.steps = [];
    }
    static run(start) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = new MultiStepInput();
            return input.stepThrough(start);
        });
    }
    stepThrough(start) {
        return __awaiter(this, void 0, void 0, function* () {
            let step = start;
            while (step) {
                this.steps.push(step);
                if (this.current) {
                    this.current.enabled = false;
                    this.current.busy = true;
                }
                try {
                    step = yield step(this);
                }
                catch (err) {
                    if (err === InputFlowAction.back) {
                        this.steps.pop();
                        step = this.steps.pop();
                    }
                    else if (err === InputFlowAction.resume) {
                        step = this.steps.pop();
                    }
                    else if (err === InputFlowAction.cancel) {
                        step = undefined;
                    }
                    else {
                        throw err;
                    }
                }
            }
            if (this.current) {
                this.current.dispose();
            }
        });
    }
    showQuickPick({ title, step, totalSteps, items, activeItem, placeholder, buttons, shouldResume }) {
        return __awaiter(this, void 0, void 0, function* () {
            const disposables = [];
            try {
                return yield new Promise((resolve, reject) => {
                    const input = vscode_1.window.createQuickPick();
                    input.title = title;
                    input.step = step;
                    input.totalSteps = totalSteps;
                    input.placeholder = placeholder;
                    input.items = items;
                    if (activeItem) {
                        input.activeItems = [activeItem];
                    }
                    input.buttons = [
                        ...(this.steps.length > 1 ? [vscode_1.QuickInputButtons.Back] : []),
                        ...(buttons || [])
                    ];
                    disposables.push(input.onDidTriggerButton(item => {
                        if (item === vscode_1.QuickInputButtons.Back) {
                            reject(InputFlowAction.back);
                        }
                        else {
                            resolve(item);
                        }
                    }), input.onDidChangeSelection(items => resolve(items[0])), input.onDidHide(() => {
                        (() => __awaiter(this, void 0, void 0, function* () {
                            reject(shouldResume && (yield shouldResume()) ? InputFlowAction.resume : InputFlowAction.cancel);
                        }))()
                            .catch(reject);
                    }));
                    if (this.current) {
                        this.current.dispose();
                    }
                    this.current = input;
                    this.current.show();
                });
            }
            finally {
                disposables.forEach(d => d.dispose());
            }
        });
    }
    showInputBox({ title, step, totalSteps, value, prompt, validate, buttons, shouldResume }) {
        return __awaiter(this, void 0, void 0, function* () {
            const disposables = [];
            try {
                return yield new Promise((resolve, reject) => {
                    const input = vscode_1.window.createInputBox();
                    input.title = title;
                    input.step = step;
                    input.totalSteps = totalSteps;
                    input.value = value || '';
                    input.prompt = prompt;
                    input.buttons = [
                        ...(this.steps.length > 1 ? [vscode_1.QuickInputButtons.Back] : []),
                        ...(buttons || [])
                    ];
                    let validating = validate('');
                    disposables.push(input.onDidTriggerButton(item => {
                        if (item === vscode_1.QuickInputButtons.Back) {
                            reject(InputFlowAction.back);
                        }
                        else {
                            resolve(item);
                        }
                    }), input.onDidAccept(() => __awaiter(this, void 0, void 0, function* () {
                        const value = input.value;
                        input.enabled = false;
                        input.busy = true;
                        if (!(yield validate(value))) {
                            resolve(value);
                        }
                        input.enabled = true;
                        input.busy = false;
                    })), input.onDidChangeValue((text) => __awaiter(this, void 0, void 0, function* () {
                        const current = validate(text);
                        validating = current;
                        const validationMessage = yield current;
                        if (current === validating) {
                            input.validationMessage = validationMessage;
                        }
                    })), input.onDidHide(() => {
                        (() => __awaiter(this, void 0, void 0, function* () {
                            reject(shouldResume && (yield shouldResume()) ? InputFlowAction.resume : InputFlowAction.cancel);
                        }))()
                            .catch(reject);
                    }));
                    if (this.current) {
                        this.current.dispose();
                    }
                    this.current = input;
                    this.current.show();
                });
            }
            finally {
                disposables.forEach(d => d.dispose());
            }
        });
    }
}
/**
 * A multi-step input using window.createQuickPick() and window.createInputBox().
 *
 * This first part uses the helper class `MultiStepInput` that wraps the API for the multi-step case.
 */
function multiStepInput(context) {
    return __awaiter(this, void 0, void 0, function* () {
        class MyButton {
            constructor(iconPath, tooltip) {
                this.iconPath = iconPath;
                this.tooltip = tooltip;
            }
        }
        const setSrcVersionButton = new MyButton({
            dark: vscode_1.Uri.file(context.asAbsolutePath('resources/dark/add.svg')),
            light: vscode_1.Uri.file(context.asAbsolutePath('resources/light/add.svg')),
        }, 'setSrcVersion');
        const setTargetVersionButton = new MyButton({
            dark: vscode_1.Uri.file(context.asAbsolutePath('resources/dark/add.svg')),
            light: vscode_1.Uri.file(context.asAbsolutePath('resources/light/add.svg')),
        }, 'setTargetVersion');
        const sourceVersionGroup = ['AzureVM', 'Az1.0', 'Az2.0', 'Az3.0']
            .map(label => ({ label }));
        const targetVersionGroup = ['Az1.0', 'Az2.0', 'Az3.0', 'Az4.0']
            .map(label => ({ label }));
        function collectInputs() {
            return __awaiter(this, void 0, void 0, function* () {
                const state = {};
                yield MultiStepInput.run(input => setSourceVersionQuickPick(input, state));
                return state;
            });
        }
        const title = 'Set Migration Parameter';
        function setSourceVersionBox(input, state) {
            return __awaiter(this, void 0, void 0, function* () {
                state.srcVersion = yield input.showInputBox({
                    title,
                    step: 1,
                    totalSteps: 2,
                    value: typeof state.srcVersion === 'string' ? state.srcVersion : '',
                    prompt: 'Set Source Version',
                    validate: validateNameIsUnique,
                    shouldResume: shouldResume
                });
                return (input) => setTargetVersionBox(input, state);
            });
        }
        function setSourceVersionQuickPick(input, state) {
            return __awaiter(this, void 0, void 0, function* () {
                const pick = yield input.showQuickPick({
                    title,
                    step: 1,
                    totalSteps: 2,
                    placeholder: 'Set Source Version',
                    items: sourceVersionGroup,
                    activeItem: typeof state.srcVersion !== 'string' ? state.srcVersion : undefined,
                    buttons: [setSrcVersionButton],
                    shouldResume: shouldResume
                });
                if (pick instanceof MyButton) {
                    return (input) => setSourceVersionBox(input, state);
                }
                state.srcVersion = pick.label;
                return (input) => setTargetVersionQuickPick(input, state);
            });
        }
        function setTargetVersionBox(input, state) {
            return __awaiter(this, void 0, void 0, function* () {
                state.targetVersion = yield input.showInputBox({
                    title,
                    step: 2,
                    totalSteps: 2,
                    value: typeof state.targetVersion === 'string' ? state.targetVersion : '',
                    prompt: 'Set Target Version',
                    validate: validateNameIsUnique,
                    shouldResume: shouldResume
                });
            });
        }
        function setTargetVersionQuickPick(input, state) {
            return __awaiter(this, void 0, void 0, function* () {
                const pick = yield input.showQuickPick({
                    title,
                    step: 2,
                    totalSteps: 2,
                    placeholder: 'Set Target Version',
                    items: targetVersionGroup,
                    activeItem: typeof state.targetVersion !== 'string' ? state.targetVersion : undefined,
                    buttons: [setTargetVersionButton],
                    shouldResume: shouldResume
                });
                if (pick instanceof MyButton) {
                    return (input) => setTargetVersionBox(input, state);
                }
                state.targetVersion = pick.label;
            });
        }
        function shouldResume() {
            // Could show a notification with the option to resume.
            return new Promise((resolve, reject) => {
                // noop
            });
        }
        function validateNameIsUnique(name) {
            return __awaiter(this, void 0, void 0, function* () {
                // ...validate...
                yield new Promise(resolve => setTimeout(resolve, 1000));
                return name === 'vscode' ? 'Version not unique' : undefined;
            });
        }
        const state = yield collectInputs();
        vscode_1.window.showInformationMessage(`Translating powershell scripts from  '${state.srcVersion}' to '${state.targetVersion}'`);
        return [state.srcVersion, state.targetVersion];
    });
}
exports.multiStepInput = multiStepInput;
//# sourceMappingURL=multiStepInput.js.map