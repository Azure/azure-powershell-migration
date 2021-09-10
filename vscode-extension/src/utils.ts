/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

'use strict';

import fs = require('fs');
import os = require('os');
import path = require('path');

export const PowerShellLanguageId = 'powershell';

export function ensurePathExists(targetPath: string): void {
    // Ensure that the path exists
    try {
        fs.mkdirSync(targetPath);
    } catch (e) {
        // If the exception isn't to indicate that the folder exists already, rethrow it.
        if (e.code !== 'EEXIST') {
            throw e;
        }
    }
}

export function getPipePath(pipeName: string): string {
    if (os.platform() === 'win32') {
        return '\\\\.\\pipe\\' + pipeName;
    } else {
        // Windows uses NamedPipes where non-Windows platforms use Unix Domain Sockets.
        // This requires connecting to the pipe file in different locations on Windows vs non-Windows.
        return path.join(os.tmpdir(), `CoreFxPipe_${pipeName}`);
    }
}

export interface IEditorServicesSessionDetails {
    status: string;
    reason: string;
    detail: string;
    powerShellVersion: string;
    channel: string;
    languageServicePort: number;
    debugServicePort: number;
    languageServicePipeName: string;
    debugServicePipeName: string;
}

export type IReadSessionFileCallback = (
    details: IEditorServicesSessionDetails
) => void;

const sessionsFolder = path.resolve(__dirname, '..', '..', 'sessions/');
const sessionFilePathPrefix = path.resolve(
    sessionsFolder,
    'PSES-VSCode-' + process.env.VSCODE_PID
);

// Create the sessions path if it doesn't exist already
ensurePathExists(sessionsFolder);

export function getSessionFilePath(uniqueId: number): string {
    return `${sessionFilePathPrefix}-${uniqueId}`;
}

export function getDebugSessionFilePath(): string {
    return `${sessionFilePathPrefix}-Debug`;
}

export function writeSessionFile(
    sessionFilePath: string,
    sessionDetails: IEditorServicesSessionDetails
): void {
    ensurePathExists(sessionsFolder);

    const writeStream = fs.createWriteStream(sessionFilePath);
    writeStream.write(JSON.stringify(sessionDetails));
    writeStream.close();
}

export function readSessionFile(
    sessionFilePath: string
): IEditorServicesSessionDetails {
    const fileContents = fs.readFileSync(sessionFilePath, 'utf-8');
    return JSON.parse(fileContents);
}

export function deleteSessionFile(sessionFilePath: string): void {
    try {
        fs.unlinkSync(sessionFilePath);
    } catch (e) {
        // TODO: Be more specific about what we're catching
    }
}

export function checkIfFileExists(filePath: string): boolean {
    try {
        fs.accessSync(filePath, fs.constants.R_OK);
        return true;
    } catch (e) {
        return false;
    }
}

export function getTimestampString(): string {
    const time = new Date();
    return `[${time.getHours()}:${time.getMinutes()}:${time.getSeconds()}]`;
}

export function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

export function readAliasFile(aliasFilePath: string): string {
    const fileContents = fs.readFileSync(aliasFilePath, 'utf-8');
    return fileContents;
}

/**
 * Return a new function that when run multiple times within `delay`, only the last one will actually run.
 * @param callback the function you want to debounce
 * @param delay how long in ms will the callback be called
 * @returns a new function that has the same input as callback but does not return
 */
export function debounce<T, Y extends unknown[]>(
    callback: Action<T, Y>,
    delay: number
): Action<void, Y> {
    let timer: NodeJS.Timeout;
    return (...args: Y) => {
        clearTimeout(timer);
        timer = setTimeout(() => {
            callback(...args);
        }, delay);
    };
}

type Action<T, Y extends unknown[]> = (...args: Y) => T;


export const isMacOS: boolean = process.platform === 'darwin';
export const isWindows: boolean = process.platform === 'win32';
export const isLinux: boolean = !isMacOS && !isWindows;
