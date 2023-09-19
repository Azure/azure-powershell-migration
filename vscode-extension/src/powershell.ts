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

    //exec the migration command and get the result to latest Az version
    public async getUpgradePlanToLatest(filePath: string, azureRmVersion: string): Promise<string> {
        if (this.powershell.invocationStateInfo == "Running") {
            //the latter cancels the former powershell process
            await this.restart();
        }

        const command = `New-AzUpgradeModulePlan -FilePath "${filePath}" -FromAzureRmVersion "${azureRmVersion}" -ToAzVersion "latest" | ConvertTo-Json`;
        this.powershell.addCommand(command);
        const planResult = await this.powershell.invoke();

        return planResult;
    }

    //exec the migration command and get the result to LTS Az version
    public async getUpgradePlanToLTS(filePath: string, azureRmVersion: string): Promise<string> {
        //TODO: Implement this in the future when LTS ready
        return;
    }

    //check whether the module exists
    public checkModuleExist(moduleName: string): boolean {
        const systemModulePath = this.getSystemModulePath();

        return systemModulePath.some(
            moduleFolder => fs.existsSync(path.resolve(moduleFolder, moduleName))
        );

    }

    //check the version of the installed module
    public checkModuleVersion(moduleName: string): string {
        const systemModulePath = this.getSystemModulePath();
        let moduleFolder = systemModulePath.find(
            moduleFolder => fs.existsSync(path.resolve(moduleFolder, moduleName))
        );
        moduleFolder = path.join(moduleFolder, moduleName);
        const versions = fs.readdirSync(moduleFolder);
        let latest = versions[0];
        for (let i = 1; i < versions.length; i++) {
            if (this.versionCompare(versions[i], latest) > 0) {
                latest = versions[i];
            }
        }
        return latest;
    }

    public versionCompare(v1, v2): number {
        v1 = v1.split('.');
        v2 = v2.split('.');
        const k = Math.min(v1.length, v2.length);
        for (let i = 0; i < k; i++) {
            v1[i] = parseInt(v1[i], 10);
            v2[i] = parseInt(v2[i], 10);
            if (v1[i] > v2[i]) return 1;
            if (v1[i] < v2[i]) return -1;        
        }
        return v1.length == v2.length ? 0: (v1.length < v2.length ? -1 : 1);
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