/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import shell = require("node-powershell");
import { Logger } from "./logging";
import * as process from "process";
import path = require("path");
import fs = require("fs");

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
        this.powershell.addCommand(command);
        const planResult = await this.powershell.invoke();

        return planResult;
    }

    public async getCustomAlias(filePath: string): Promise<string> {
        const command = `Invoke-ScriptAnalyzer -Path ${filePath} -Settings C:\\Users\\t-zenli\\workspace\\dev\\azure-powershell-migration\\vscode-extension\\PSA_custom_Rules\\CustomRules.psm1 -ErrorAction SilentlyContinue| ConvertTo-Json -depth 10`;
        this.powershell.addCommand(command);
        const aliasResult = await this.powershell.invoke();

        return aliasResult;
    }

    //check whether the module exists
    public checkModuleExist(moduleName: string): boolean {
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