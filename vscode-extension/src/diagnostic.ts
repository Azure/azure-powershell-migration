/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import * as vscode from 'vscode';
import { PowershellProcess } from './powershell';
import { Logger } from "./logging";
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
        try {
            log.write(`Start analyzing ${documentUri.fsPath}`);
            planResult = await powershell.getUpgradePlan(documentUri.fsPath, azureRmVersion, azVersion);
            log.write(`Node-Powershell Success. -- ${documentUri.fsPath}`);
        }
        catch (e) {
            log.writeError(`Error: Node-Powershell failed.`);
        }

        //update the content of diagnostic
        if (planResult) {
            let diagnostics: vscode.Diagnostic[] = formatPlanstToDiag(planResult, log);
            diagcCollection.set(documentUri, diagnostics);
            log.write(`Diagnostics Number : ${diagnostics.length}  `);
        }
        else {
            log.write(`This file is not need to be migrated.`);
        }


    } else {
        diagcCollection.clear();
    }

}

/**
 * Format the palnStr to diganostic.
 * @param plansStr : The result(string) of migration.
 * @param log : Logger
 * @returns : diagnostics
 */
function formatPlanstToDiag(plansStr: string, log: Logger): vscode.Diagnostic[] {
    let plans: object[];
    try {
        plans = JSON.parse(plansStr);
    }
    catch {
        log.writeError("The result of Migration is wrong!");
        return [];
    }

    let diagnostics: vscode.Diagnostic[] = [];
    plans.forEach(
        (plan: any) => {
            let range = new vscode.Range(new vscode.Position(plan.SourceCommand.StartLine - 1, plan.SourceCommand.StartColumn - 1),
                new vscode.Position(plan.SourceCommand.EndLine - 1, plan.SourceCommand.EndPosition - 1));
            let message = plan.PlanResultReason;
            let diagnostic = new vscode.Diagnostic(range, message);
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

