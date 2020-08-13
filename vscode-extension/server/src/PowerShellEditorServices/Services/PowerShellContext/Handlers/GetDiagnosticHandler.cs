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
    [Serial, Method("powerShell/getDiagnostic")]
    internal interface IGetDiagnosticHandler : IJsonRpcRequestHandler<DiagnosticRequest, DiagnosticResponse> { }

    internal class DiagnosticResponse
    {
        public Diagnostic[] diagnostics { get; set; }
    }

    internal class DiagnosticRequest : IRequest<DiagnosticResponse>
    {
        public string Content { get; set; }
    }

    internal class GetDiagnosticHandler : IGetDiagnosticHandler
    {
        private readonly ILogger<GetDiagnosticHandler> _logger;
        private readonly PowerShellContextService _powerShellContextService;

        public GetDiagnosticHandler(ILoggerFactory factory, PowerShellContextService powerShellContextService)
        {
            _logger = factory.CreateLogger<GetDiagnosticHandler>();
            _powerShellContextService = powerShellContextService;
        }

        public Task<DiagnosticResponse> Handle(DiagnosticRequest request, CancellationToken cancellationToken)
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
            }
            DiagnosticResponse response =  new DiagnosticResponse {
                diagnostics = diags
            };

            return Task.FromResult<DiagnosticResponse>(response);
        }
    }
}
