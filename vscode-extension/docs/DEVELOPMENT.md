# Dev notes

## Packaging

Be sure to include `--baseImagesUrl` when packaging the extension otherwise the image links would be broken after installing the extension.

```
vsce package --baseImagesUrl https://raw.githubusercontent.com/Azure/azure-powershell-migration/main/vscode-extension
```