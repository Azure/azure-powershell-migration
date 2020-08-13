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

namespace Microsoft.PowerShell.EditorServices.Handlers
{
    [Serial, Method("powerShell/getAst")]
    internal interface IGetAstHandler : IJsonRpcRequestHandler<AstRequest, AstResponse> { }

    internal class AstResponse
    {
        // public ScriptBlockAst RootNode { get; set; }
        // public Token[] Token { get; set; }
        // public ParseError[] ParseError { get; set; }
        public string Content { get; set; }
    }

    internal class AstRequest : IRequest<AstResponse>
    {
        public string Content { get; set; }
    }

    internal class GetAstHandler : IGetAstHandler
    {
        private readonly ILogger<GetAstHandler> _logger;
        private readonly PowerShellContextService _powerShellContextService;

        public GetAstHandler(ILoggerFactory factory, PowerShellContextService powerShellContextService)
        {
            _logger = factory.CreateLogger<GetAstHandler>();
            _powerShellContextService = powerShellContextService;
        }

        public Task<AstResponse> Handle(AstRequest request, CancellationToken cancellationToken)
        {
            Token[] token = null;
            ParseError[] parseError = null;
            ScriptBlockAst rootNode = Parser.ParseInput(request.Content, out token, out parseError);
            AstResponse response =  new AstResponse {
                // RootNode = rootNode,
                // Token = token,
                // ParseError = parseError
                Content = request.Content
            };
            Console.WriteLine("=====================================");
            Console.WriteLine("GetAst service: " + request.Content);
            Console.WriteLine("GetAst result: " + rootNode.ToString());
            Console.WriteLine("=====================================");

            return Task.FromResult<AstResponse>(response);
        }
    }
}
