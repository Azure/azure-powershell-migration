/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import * as vscode from 'vscode';
import shell = require("node-powershell");
import { Logger } from "./logging";
import * as process from "process";
import { homedir } from 'os';
import path = require("path");
import fs = require("fs");
import { promises } from 'dns';

/**
 * Manage the powershell process.
 */
export class PowershellProcess {

    private powershell: shell;
    private log: Logger;

    //start a powershell process
    public start(): void {
        this.powershell = new shell({
            executionPolicy: 'Bypass',
            noProfile: true
        });
    }

    //exec the migration command and get the result
    public async getUpgradePlan(filePath: string, azureRmVersion: string, azVersion: string): Promise<string> {
        //const command = `New-AzUpgradeModulePlan -FilePath "${filePath}" -FromAzureRmVersion "${azureRmVersion}" -ToAzVersion "${azVersion}" | ConvertTo-Json -depth 10`;
        if (this.powershell.invocationStateInfo == "Running") {
            //the latter cancels the former powershell process
            await this.restart();
        }

        const command = `New-AzUpgradeModulePlan -FilePath "${filePath}" -FromAzureRmVersion "${azureRmVersion}" -ToAzVersion "${azVersion}" | ConvertTo-Json`;
        let planResult;
        this.powershell.addCommand(command);
        planResult = await this.powershell.invoke();

        return planResult;
    }

    //exec the avoidCustomAlias command from PSA and get the result
    public async getCustomAlias(filePath: string) {

        // const command = `Invoke-ScriptAnalyzer -Path ${filePath} -CustomRulePath  ${customFuleFile} | ConvertTo-Json`;
        const command = `Invoke-ScriptAnalyzer -Path ${filePath} -CustomRulePath C:\\Users\\t-zenli\\workspace\\dev\\azure-powershell-migration\\vscode-extension\\PSA_custom_Rules\\Alias\\avoidAlias.psm1 | ConvertTo-Json -depth 10`;
        //const command = `Invoke-ScriptAnalyzer -Path ${filePath} | ConvertTo-Json`;
        let aliasResult;
        this.powershell.addCommand(command);
        aliasResult = await this.powershell.invoke();
        //aliasResult = JSON.parse(aliasResult);
        // try {
        //     console.log(aliasResult[0].SuggestedCorrections[0].Text);
        // }
        // catch {
        //     console.log(aliasResult.SuggestedCorrections[0].Text);
        // }



        return aliasResult;
    }

    public async getBreakingChange(filePath: string) {

        // const command = `Invoke-ScriptAnalyzer -Path ${filePath} -CustomRulePath  ${customFuleFile} | ConvertTo-Json`;
        const command = `Invoke-ScriptAnalyzer -Path ${filePath} -CustomRulePath C:\\Users\\t-zenli\\workspace\\dev\\azure-powershell-migration\\vscode-extension\\PSA_custom_Rules\\BreakingChange\\upcomingBreakingChange.psm1 | ConvertTo-Json -depth 10`;
        //const command = `Invoke-ScriptAnalyzer -Path ${filePath} | ConvertTo-Json`;
        let breakingChangeResult;
        this.powershell.addCommand(command);
        breakingChangeResult = await this.powershell.invoke();
        //aliasResult = JSON.parse(aliasResult);
        // try {
        //     console.log(aliasResult[0].SuggestedCorrections[0].Text);
        // }
        // catch {
        //     console.log(aliasResult.SuggestedCorrections[0].Text);
        // }


        return breakingChangeResult;
    }

    //check whether the module exists
    public checkModuleExist(moduleName: string) {
        const systemModulePath = this.getSystemModulePath();

        return systemModulePath.some(
            moduleFolder => fs.existsSync(path.resolve(moduleFolder, moduleName))
        );

    }

    //install the module automatically
    public async installModule(moduleName: string): Promise<void> {
        const command = `Install-Module "${moduleName}" -Repository PSGallery -Force`;
        this.powershell.addCommand(command);
        await this.powershell.invoke().then(
            () => { this.log.write(`Install "${moduleName}" successed`); }
        );
    }

    //get the env path of ps-modules
    public getSystemModulePath(): string[] {
        if (process.platform === "win32") { //windows
            //this.systemModulePath = homedir() + "\\Documents\\PowerShell\\Modules\\";
            const PsModulePathes = process.env.PSMODULEPATH.split(";");
            return PsModulePathes;
        } else if (process.platform === "darwin" || process.platform === "linux") { //Linux or MacOS
            //this.systemModulePath.push(homedir() + "/.local/share/powershell/Modules: usr/local/share/powershell/Modules");
            const PsModulePathes = process.env.PSMODULEPATH.split(":");
            return PsModulePathes;
        }
        else {
            console.log("Unsupported operating system!");
            return [];
        }
    }

    //stop the powershell process
    public async stop(): Promise<void> {
        await this.powershell.dispose();
    }

    //restart the powershell process
    public async restart(): Promise<void> {
        process.kill(this.powershell.pid);
        //await this.powershell.dispose();
        await this.start();
    }

}