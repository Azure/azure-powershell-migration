//
// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
//
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Threading;
using System.Threading.Tasks;
using System.Management.Automation.Language;
using Microsoft.Extensions.Logging;
using Microsoft.PowerShell.EditorServices.Services;
using MediatR;
using OmniSharp.Extensions.JsonRpc;
using OmniSharp.Extensions.LanguageServer.Protocol.Models;
using System.IO;

namespace Microsoft.PowerShell.EditorServices.Handlers
{
    [Serial, Method("powerShell/getCodeAction")]
    internal interface IGetCodeActionHandler : IJsonRpcRequestHandler<CodeActionRequest, CodeActionResponse> { }

    internal class CodeActionResponse
    {
        public Diagnostic[] diagnostics { get; set; }
        public CodeAction[] codeActions { get; set; }
    }

    internal class CodeActionRequest : IRequest<CodeActionResponse>
    {
        public string Content { get; set; }
    }

    internal class GetCodeActionHandler : IGetCodeActionHandler
    {
        private readonly ILogger<GetCodeActionHandler> _logger;
        private readonly PowerShellContextService _powerShellContextService;

        public GetCodeActionHandler(ILoggerFactory factory, PowerShellContextService powerShellContextService)
        {
            _logger = factory.CreateLogger<GetCodeActionHandler>();
            _powerShellContextService = powerShellContextService;
        }

        public Task<CodeActionResponse> Handle(CodeActionRequest request, CancellationToken cancellationToken)
        {

            string path = "analysis.ps1";
            using (StreamWriter sw = File.CreateText(path))
            {
                sw.Write(request.Content);
            }

            var powershell = System.Management.Automation.PowerShell.Create();
            powershell.AddScript("Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process");
            powershell.AddScript(@"Import-Module C:\Users\t-chenly\Documents\Github\azure-powershell-migration\powershell-module\Az.Tools.Migration\Az.Tools.Migration.psd1");
            // powershell.AddScript(@"$plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath C:\Users\t-chenly\Documents\test.ps1");
            powershell.AddScript(@"$plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath analysis.ps1");
            powershell.AddScript(@"$plan.UpgradeSteps");
            var upgradeSteps = powershell.Invoke();
            var diags = new Diagnostic[upgradeSteps.Count];
            var actions = new CodeAction[upgradeSteps.Count];
            int i = 0;
            foreach (var upgradeStep in upgradeSteps)
            {
                var info = upgradeStep.ImmediateBaseObject;
                string file = info.GetType().GetProperty("FileName").GetValue(info, null).ToString();
                string message = info.GetType().GetProperty("OriginalCmdletName").GetValue(info, null).ToString();
                int startLine = (int)info.GetType().GetProperty("StartLine").GetValue(info, null);
                int startColumn = (int)info.GetType().GetProperty("StartColumn").GetValue(info, null);
                int startOffset = (int)info.GetType().GetProperty("StartOffset").GetValue(info, null);
                int endLine = (int)info.GetType().GetProperty("EndLine").GetValue(info, null);
                int endColumn = (int)info.GetType().GetProperty("EndPosition").GetValue(info, null);
                int endOffset = (int)info.GetType().GetProperty("EndOffset").GetValue(info, null);

                var diag = new Diagnostic();
                diag.Code = "CMDLET_RENAME";
                diag.Message = message;
                diag.Range = new Range(new Position(startLine-1, startColumn-1), new Position(endLine-1, endColumn-1));
                diag.Severity = DiagnosticSeverity.Warning - 1;
                diags[i] = diag;
                i++;

                var action = new CodeAction();
                action.Edit = new WorkspaceEdit();
                action.Title = "Auto Fix";
                action.Kind = CodeActionKind.QuickFix;
                actions[i] = action;
            }
            CodeActionResponse response =  new CodeActionResponse {
                diagnostics = diags,
                codeActions = actions
            };

            return Task.FromResult<CodeActionResponse>(response);
        }
    }
}
