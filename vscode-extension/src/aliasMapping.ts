import * as fs from 'fs';
import * as path from 'path';

export function loadLatestVersionCmdletSpec() {
    var cmdlets = new Map();

    const files_dir = path.join(__dirname,'../module-spec/az-4.4.0');

    fs.readdirSync(files_dir).forEach(file => {
        const file_path=path.join(files_dir,file);
        if(fs.statSync(file_path).isFile()){
            const map = loadCmdletSpecFromFile(file_path);
            for (let key of map.keys()) {
                cmdlets.set(key.toLowerCase(), map.get(key));
            }
        }
    });

    return cmdlets;
}

export function loadSrcVersionCmdletSpec(srcVersion: string) {
    var cmdlets = new Map();
    
    const files_dir = path.join(__dirname,'../module-spec/azurerm-6.13.1');

    fs.readdirSync(files_dir).forEach(file => {
        const file_path=path.join(files_dir,file);
        if(fs.statSync(file_path).isFile()){
            const map = loadCmdletSpecFromFile(file_path);
            for (let key of map.keys()) {
                cmdlets.set(key.toLowerCase(), map.get(key));
            }
        }
    });

    return cmdlets;
}

function loadCmdletSpecFromFile(file: string) {
    const data = require(file);

    var map = new Map();
    for (var i = 0; i < data.length; i++) {
        map.set(data[i].Command, data[i]);
    }
    return map;
}

export function loadAliasMapping() {
    var aliasMap = new Map<string, string>();
    var file = '../module-spec/az-4.4.0/CmdletAliases/Aliases.json';
    var data = require(file);
    for(var i=0; i<data.length; i++) {
        aliasMap.set(data[i].Name.toLowerCase(), data[i].ResolvedCommand);
    }
    return aliasMap;
}