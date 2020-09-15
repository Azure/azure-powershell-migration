/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { QuickPickItem, window, Disposable, QuickInputButton, QuickInput, ExtensionContext, QuickInputButtons, Uri } from 'vscode';

// -------------------------------------------------------
// Helper code that wraps the API for the multi-step case.
// -------------------------------------------------------

type InputStep = (input: MultiStepInput) => Thenable<InputStep | void>;

interface QuickPickParameters<T extends QuickPickItem> {
	title: string;
	step: number;
	totalSteps: number;
	items: T[];
	activeItem?: T;
	placeholder: string;
	buttons?: QuickInputButton[];
	shouldResume: () => Thenable<boolean>;
}

class InputFlowAction {
	static back = new InputFlowAction();
	static cancel = new InputFlowAction();
	static resume = new InputFlowAction();
}


interface InputBoxParameters {
	title: string;
	step: number;
	totalSteps: number;
	value: string;
	prompt: string;
	validate: (value: string) => Promise<string | undefined>;
	buttons?: QuickInputButton[];
	shouldResume: () => Thenable<boolean>;
}

class MultiStepInput {

	static async run<T>(start: InputStep) {
		const input = new MultiStepInput();
		return input.stepThrough(start);
	}

	private current?: QuickInput;
	private steps: InputStep[] = [];

	private async stepThrough<T>(start: InputStep) {
		let step: InputStep | void = start;
		while (step) {
			this.steps.push(step);
			if (this.current) {
				this.current.enabled = false;
				this.current.busy = true;
			}
			try {
				step = await step(this);
			} catch (err) {
				if (err === InputFlowAction.back) {
					this.steps.pop();
					step = this.steps.pop();
				} else if (err === InputFlowAction.resume) {
					step = this.steps.pop();
				} else if (err === InputFlowAction.cancel) {
					step = undefined;
				} else {
					throw err;
				}
			}
		}
		if (this.current) {
			this.current.dispose();
		}
	}

	async showQuickPick<T extends QuickPickItem, P extends QuickPickParameters<T>>({ title, step, totalSteps, items, activeItem, placeholder, buttons, shouldResume }: P) {
		const disposables: Disposable[] = [];
		try {
			return await new Promise<T | (P extends { buttons: (infer I)[] } ? I : never)>((resolve, reject) => {
				const input = window.createQuickPick<T>();
				input.title = title;
				input.step = step;
				input.totalSteps = totalSteps;
				input.placeholder = placeholder;
				input.items = items;
				if (activeItem) {
					input.activeItems = [activeItem];
				}
				input.buttons = [
					...(this.steps.length > 1 ? [QuickInputButtons.Back] : []),
					...(buttons || [])
				];
				disposables.push(
					input.onDidTriggerButton(item => {
						if (item === QuickInputButtons.Back) {
							reject(InputFlowAction.back);
						} else {
							resolve(<any>item);
						}
					}),
					input.onDidChangeSelection(items => resolve(items[0])),
					input.onDidHide(() => {
						(async () => {
							reject(shouldResume && await shouldResume() ? InputFlowAction.resume : InputFlowAction.cancel);
						})()
							.catch(reject);
					})
				);
				if (this.current) {
					this.current.dispose();
				}
				this.current = input;
				this.current.show();
			});
		} finally {
			disposables.forEach(d => d.dispose());
		}
	}

	async showInputBox<P extends InputBoxParameters>({ title, step, totalSteps, value, prompt, validate, buttons, shouldResume }: P) {
		const disposables: Disposable[] = [];
		try {
			return await new Promise<string | (P extends { buttons: (infer I)[] } ? I : never)>((resolve, reject) => {
				const input = window.createInputBox();
				input.title = title;
				input.step = step;
				input.totalSteps = totalSteps;
				input.value = value || '';
				input.prompt = prompt;
				input.buttons = [
					...(this.steps.length > 1 ? [QuickInputButtons.Back] : []),
					...(buttons || [])
				];
				let validating = validate('');
				disposables.push(
					input.onDidTriggerButton(item => {
						if (item === QuickInputButtons.Back) {
							reject(InputFlowAction.back);
						} else {
							resolve(<any>item);
						}
					}),
					input.onDidAccept(async () => {
						const value = input.value;
						input.enabled = false;
						input.busy = true;
						if (!(await validate(value))) {
							resolve(value);
						}
						input.enabled = true;
						input.busy = false;
					}),
					input.onDidChangeValue(async text => {
						const current = validate(text);
						validating = current;
						const validationMessage = await current;
						if (current === validating) {
							input.validationMessage = validationMessage;
						}
					}),
					input.onDidHide(() => {
						(async () => {
							reject(shouldResume && await shouldResume() ? InputFlowAction.resume : InputFlowAction.cancel);
						})()
							.catch(reject);
					})
				);
				if (this.current) {
					this.current.dispose();
				}
				this.current = input;
				this.current.show();
			});
		} finally {
			disposables.forEach(d => d.dispose());
		}
	}
}

/**
 * A multi-step input using window.createQuickPick() and window.createInputBox().
 * 
 * This first part uses the helper class `MultiStepInput` that wraps the API for the multi-step case.
 */
export async function multiStepInput(context: ExtensionContext) {

	
	class MyButton implements QuickInputButton {
		constructor(public iconPath: { light: Uri; dark: Uri; }, public tooltip: string) { }
	}

	const setSrcVersionButton = new MyButton({
		dark: Uri.file(context.asAbsolutePath('resources/dark/add.svg')),
		light: Uri.file(context.asAbsolutePath('resources/light/add.svg')),
	}, 'setSrcVersion');

	const setTargetVersionButton = new MyButton({
		dark: Uri.file(context.asAbsolutePath('resources/dark/add.svg')),
		light: Uri.file(context.asAbsolutePath('resources/light/add.svg')),
	}, 'setTargetVersion');

	const sourceVersionGroup: QuickPickItem[] = ['AzureRM','Az 1.0','Az 2.0','Az 3.0']
		.map(label => ({ label }));

	
	const targetVersionGroup: QuickPickItem[] = ['Az 1.0','Az 2.0','Az 3.0','Az 4.0']
		.map(label => ({ label }));

	interface State {
		title: string;
		step: number;
		totalSteps: number;
		srcVersion: QuickPickItem | string;
		targetVersion: QuickPickItem | string;
	}

	async function collectInputs() {
		const state = {} as Partial<State>;
		await MultiStepInput.run(input => setSourceVersionQuickPick(input, state));
		return state as State;
	}

	const title = 'Set Migration Parameter';

	async function setSourceVersionBox(input: MultiStepInput, state: Partial<State>) {
		state.srcVersion = await input.showInputBox({
			title,
			step: 1,
			totalSteps: 2,
			value: typeof state.srcVersion === 'string' ? state.srcVersion : '',
			prompt: 'Set Source Version',
			validate: validateNameIsUnique,
			shouldResume: shouldResume
		});
		return (input: MultiStepInput) => setTargetVersionBox(input, state);
	}

	async function setSourceVersionQuickPick(input: MultiStepInput, state: Partial<State>) {
		const pick = await input.showQuickPick({
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
			return (input: MultiStepInput) => setSourceVersionBox(input, state);
		}
		state.srcVersion = pick.label;
		return (input: MultiStepInput) => setTargetVersionQuickPick(input, state);
	}

	async function setTargetVersionBox(input: MultiStepInput, state: Partial<State>) {
		state.targetVersion = await input.showInputBox({
			title,
			step: 2,
			totalSteps: 2,
			value: typeof state.targetVersion === 'string' ? state.targetVersion : '',
			prompt: 'Set Target Version',
			validate: validateNameIsUnique,
			shouldResume: shouldResume
		});
	}

	async function setTargetVersionQuickPick(input: MultiStepInput, state: Partial<State>) {
		const pick = await input.showQuickPick({
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
			return (input: MultiStepInput) => setTargetVersionBox(input, state);
		}
		state.targetVersion = pick.label;
	}


	function shouldResume() {
		// Could show a notification with the option to resume.
		return new Promise<boolean>((resolve, reject) => {
			// noop
		});
	}

	async function validateNameIsUnique(name: string) {
		// ...validate...
		await new Promise(resolve => setTimeout(resolve, 1000));
		return name === 'vscode' ? 'Version not unique' : undefined;
	}

	const state = await collectInputs();
	window.showInformationMessage(`Translating powershell scripts from  '${state.srcVersion}' to '${state.targetVersion}'`);
	return [state.srcVersion,state.targetVersion];
}

export async function getSrcVersion(){
	return window.showQuickPick(['AzureRM', 'Az1.0', 'Az2.0','Az3.0'],{
		placeHolder: 'Select source scripts version'
	});
}