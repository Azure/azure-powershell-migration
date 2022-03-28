/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

import shell = require('node-powershell');
import { Logger } from './logging';
import * as process from 'process';
import path = require('path');
import fs = require('fs');

/**
 * Manage the powershell process.
 */
export class PowershellProcess {
    private powershell: shell;
    private log: Logger;

    //start a powershell process
    public async start(): Promise<void> {
        this.powershell = new shell({
            executionPolicy: 'Bypass',
            noProfile: true
        });

        //TODO: Resolve the PSA Path question instead of copying PSA folder.
        const flagFilePath = path.resolve(__dirname, '../PSAExecPath.txt'); //if flagFile already exists, we've copied the CustomRules files to powershell execution path before
        if (!fs.existsSync(flagFilePath)) {
            const PSASourcePath = path.resolve(
                __dirname,
                '../PSA_custom_Rules'
            );
            this.powershell.addCommand(`$pwd.Path`);
            const PSAExecPath = await this.powershell.invoke();
            //copy the custom rule files to powershell execution path
            const mklinkCommand = `Copy-Item ${PSASourcePath} -Recurse '${PSAExecPath.trim()}'`;
            this.powershell.addCommand(mklinkCommand);
            await this.powershell.invoke();
            const writeStream = fs.createWriteStream(flagFilePath);
            writeStream.write(PSAExecPath);
            writeStream.close();
        }
    }

    //exec the migration command and get the result
    public async getUpgradePlan(
        filePath: string,
        azureRmVersion: string,
        azVersion: string
    ): Promise<string> {
        if (this.powershell.invocationStateInfo == 'Running') {
            //the latter cancels the former powershell process
            await this.restart();
        }

        const command = `New-AzUpgradeModulePlan -FilePath ${filePath} -FromAzureRmVersion ${azureRmVersion} -ToAzVersion ${azVersion} | ConvertTo-Json -depth 10`;
        this.powershell.addCommand(command);
        const planResult = await this.powershell.invoke();

        return planResult;
    }

    public async getCustomSuggestions(
        filePath: string,
        settingPath: string
    ): Promise<string> {
        //ignore errors through "-ErrorAction SilentlyContinue"
        const command = `Invoke-ScriptAnalyzer -Path ${filePath} -Settings ${settingPath} -ErrorAction SilentlyContinue| ConvertTo-Json -depth 10`;
        this.powershell.addCommand(command);
        const aliasResult = await this.powershell.invoke();

        return aliasResult;
    }

    //check whether the module exists
    public checkModuleExist(moduleName: string): boolean {
        const systemModulePath = this.getSystemModulePath();

        return systemModulePath.some((moduleFolder) =>
            fs.existsSync(path.resolve(moduleFolder, moduleName))
        );
    }

    //install the module automatically
    public async installModule(moduleName: string): Promise<void> {
        const command = `Install-Module "${moduleName}" -Repository PSGallery -Force`;
        this.powershell.addCommand(command);
        await this.powershell.invoke();
        this.log.write(`Install "${moduleName}" successed`);
    }

    //get the env path of ps-modules
    public getSystemModulePath(): string[] {
        if (process.platform === 'win32') {
            //windows
            const PsModulePathes = process.env.PSMODULEPATH.split(';');
            return PsModulePathes;
        } else if (
            process.platform === 'darwin' ||
            process.platform === 'linux'
        ) {
            //Linux or MacOS
            const PsModulePathes = process.env.PSMODULEPATH.split(':');
            return PsModulePathes;
        } else {
            this.log.writeError(`Unsupported operating system ${process.platform}`);
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
        await this.start();
    }
}
