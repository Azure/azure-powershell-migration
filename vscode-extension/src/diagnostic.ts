/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import * as vscode from 'vscode';
import { PowershellProcess } from './powershell';
import { Logger } from "./logging";
import { UpgradePlan } from "./types/migraion";
import { SuggestedCorrection } from './types/PSScriptAnalyzer';
import path = require('path');
import fs = require("fs");
import { sleep } from './utils';
/**
 * Updates all the diagnostics items in document.
 * @param documentUri : file path
 * @param diagcCollection : manage the diagnostics
 * @param powershell : powershell process manager
 * @param azureRmVersion : version of azureRM
 * @param azVersion : version of az
 * @param log : Logger
 */
export async function updateDiagnostics(
    documentUri: vscode.Uri,
    diagcCollection: vscode.DiagnosticCollection,
    powershell: PowershellProcess,
    azureRmVersion: string,
    azVersion: string,
    log: Logger): Promise<void> {
    if (documentUri) {
        //exec the migration powershell command
        let planResult: string;
        let PSAResult: string;
        try {
            log.write(`Start analyzing ${documentUri.fsPath} by Az.Tools.Migration.`);
            planResult = await powershell.getUpgradePlan(documentUri.fsPath, azureRmVersion, azVersion);
            log.write(`Migrate Success. -- ${documentUri.fsPath} .`);
            const settingPSA = path.resolve(__dirname, "../PSA_custom_Rules/CustomRules.psm1");
            log.write(`Start analyzing ${documentUri.fsPath} by PowershellScriptAnalyzer custom rules.`);
            PSAResult = await powershell.getCustomSuggestions(documentUri.fsPath, settingPSA);
            log.write(`PSA analyse Success. -- ${documentUri.fsPath} .`);
        }
        catch (e) {
            log.writeError(`Error: Node-Powershell failed.`);
            log.writeError(e.message);
        }

        //update the content of diagnostic
        let diagnostics: vscode.Diagnostic[] = [];
        if (planResult) {
            diagnostics = formatPlanstToDiag(planResult, log, diagnostics);
        }
        else {
            log.write(`This file is not need to be migrated.`);
        }

        if (PSAResult) {
            diagnostics = formatPsaSuggestsToDiag(PSAResult, log, diagnostics);
        }
        else {
            log.write(`This file has no alias or breakingchange.`);
        }

        log.write(`Diagnostics Number : ${diagnostics.length}  `);
        diagcCollection.set(documentUri, diagnostics);


    } else {
        diagcCollection.clear();
    }

}

/**
 * Format the palnStr of migration to diganostic.
 * @param plansStr : The result(string) of migration.
 * @param log : Logger
 * @returns : diagnostics
 */
function formatPlanstToDiag(plansStr: string, log: Logger, diagnostics: vscode.Diagnostic[]): vscode.Diagnostic[] {
    let plans: UpgradePlan[];
    try {
        plans = JSON.parse(plansStr);
    }
    catch {
        log.writeError("The result of Migration is wrong!");
        return diagnostics;
    }

    plans.forEach(
        plan => {
            const range = new vscode.Range(new vscode.Position(plan.SourceCommand.StartLine - 1, plan.SourceCommand.StartColumn - 1),
                new vscode.Position(plan.SourceCommand.EndLine - 1, plan.SourceCommand.EndPosition - 1));
            const message = plan.PlanResultReason;
            const diagnostic = new vscode.Diagnostic(range, message);
            if (plan.PlanSeverity == 1) {
                diagnostic.severity = vscode.DiagnosticSeverity.Error;
                diagnostic.code = "DO_NOTHING";
                diagnostic.source = '';
            }
            else if (plan.PlanSeverity == 2) {
                diagnostic.severity = vscode.DiagnosticSeverity.Information;
                diagnostic.code = "DO_NOTHING";
                diagnostic.source = '';
            }
            else {	//plan.PlanSeverity == 3
                diagnostic.severity = vscode.DiagnosticSeverity.Warning;
                diagnostic.code = "RENAME";
                diagnostic.source = plan.Replacement;
            }
            diagnostics.push(diagnostic);
        }
    );

    return diagnostics;
}


/**
 * Format the palnStr of PSA to diganostic.
 * @param plansStr : The result(string) of PSA.
 * @param log : Logger
 * @param diagnostics: original diagnostics list
 * @returns : diagnostics
 */
function formatPsaSuggestsToDiag(plansStr: string, log: Logger, diagnostics: vscode.Diagnostic[]): vscode.Diagnostic[] {
    let plans: SuggestedCorrection[] = [];
    const NumOfRules = 2;
    try {
        const plansStr_json = JSON.parse(plansStr);
        for (let i = 0; i < NumOfRules; i++) {
            const suggestions = plansStr_json[i].SuggestedCorrections;
            plans = [...plans, ...suggestions];
        }

    }
    catch (e) {
        log.write(e.message);
        try {
            plans = JSON.parse(plansStr).SuggestedCorrections;
        }
        catch {
            log.writeError("The result of Migration is wrong!");
            return diagnostics;
        }

    }

    plans.forEach(
        plan => {
            const range = new vscode.Range(new vscode.Position(plan.StartLineNumber - 1, plan.StartColumnNumber - 1),
                new vscode.Position(plan.EndLineNumber - 1, plan.EndColumnNumber - 1));
            const message = plan.Description;
            const diagnostic = new vscode.Diagnostic(range, message);
            diagnostic.severity = vscode.DiagnosticSeverity.Warning;
            if (plan.Description === "The alias can be changed to be formal name.") {
                diagnostic.code = "Alias";
            }
            else {
                diagnostic.code = "BreakingChange";
            }
            diagnostic.source = plan.Text;
            diagnostics.push(diagnostic);
        }
    );

    return diagnostics;
}


/**
 * Refresh the diagnostics when the file is changed.
 * @param content : content of changed file
 * @param documentUri : file path
 * @param diagcCollection : manage the diagnostics
 * @param powershell : powershell process manager
 * @param azureRmVersion : version of azureRM
 * @param azVersion : version of az
 * @param log : Logger
 */
export async function refreshDiagnosticsChange(
    content: string,
    documentUri: vscode.Uri,
    diagcCollection: vscode.DiagnosticCollection,
    powershell: PowershellProcess,
    azureRmVersion: string,
    azVersion: string,
    log: Logger): Promise<void> {
    if (content) {
        //write the content of changed file into tempfile
        const tempFilePath = path.resolve(__dirname, "../migTempFile.ps1");
        const writeStream = fs.createWriteStream(tempFilePath);
        writeStream.write(content);
        writeStream.close();
        await sleep(500);   //avoid the conflict of write and read

        //exec the migration powershell command
        let planResult: string;
        let PSAResult: string;
        try {
            log.write(`Start analyzing ${documentUri.fsPath} by Az.Tools.Migration.`);
            planResult = await powershell.getUpgradePlan(tempFilePath, azureRmVersion, azVersion);
            log.write(`Migrate Success. -- ${documentUri.fsPath} .`);
            const settingPSA = path.resolve(__dirname, "../PSA_custom_Rules/CustomRules.psm1");
            log.write(`Start analyzing ${documentUri.fsPath} by PowershellScriptAnalyzer custom rules.`);
            PSAResult = await powershell.getCustomSuggestions(tempFilePath, settingPSA);
            log.write(`PSA analyse Success. -- ${documentUri.fsPath} .`);
        }
        catch (e) {
            log.writeError(`Error: Node-Powershell failed.`);
            log.writeError(e.message);
        }

        //update the content of diagnostic
        let diagnostics: vscode.Diagnostic[] = [];
        if (planResult) {
            diagnostics = formatPlanstToDiag(planResult, log, diagnostics);

        }
        else {
            log.write(`This file is not need to be migrated.`);
        }

        if (PSAResult) {
            diagnostics = formatPsaSuggestsToDiag(PSAResult, log, diagnostics);
        }
        else {
            log.write(`This file has no alias or breakingchange.`);
        }

        log.write(`Diagnostics Number : ${diagnostics.length}  `);
        diagcCollection.set(documentUri, diagnostics);
    }

}