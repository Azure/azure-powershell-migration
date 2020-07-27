export function loadAzCmdletSpec() {
    const cmdlets = new Map();

    var files = ['../module-spec/az-4.4.0/Az.Accounts.1.9.1.Cmdlets.json',
                 '../module-spec/az-4.4.0/Az.KeyVault.2.0.0.Cmdlets.json',
                 '../module-spec/az-4.4.0/Az.Resources.2.3.0.Cmdlets.json'
                ];
    for (let file of files) {
        var map = loadCmdletSpecFromFile(file);
        for (let key of map.keys()) {
            cmdlets.set(key, map.get(key));
        }
    }
    return cmdlets;
}

export function loadAzureRMCmdletSpec() {
    const cmdlets = new Map();

    var files = ['../module-spec/azurerm-6.13.1/AzureRM.Profile.5.8.2.Cmdlets.json',
                 '../module-spec/azurerm-6.13.1/AzureRM.KeyVault.5.2.1.Cmdlets.json',
                 '../module-spec/azurerm-6.13.1/AzureRM.Resources.6.7.3.Cmdlets.json'
                ];
    for (let file of files) {
        var map = loadCmdletSpecFromFile(file);
        for (let key of map.keys()) {
            cmdlets.set(key, map.get(key));
        }
    }
    return cmdlets;
}

function loadCmdletSpecFromFile(file: string) {
    const data = require(file);

    const map = new Map();
    for(var i =0; i<data.length; i++) {
        map.set(data[i].Command, data[i]);
    }
    return map;
}