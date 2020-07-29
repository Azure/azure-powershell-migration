# Contributing to Azure PowerShell migration tools

We welcome and appreciate contributions from the community.
You can be involved and contribute to this project in many ways:

- Opening issues or submitting feature requests
- Writing and improving documentation
- Contributing to code

Please read the rest of this document for detailed information about the contribution process.

## GitHub

- Make sure you have a [GitHub account](https://github.com/signup/free).
- Learning Git:
  - GitHub Help: [Good Resources for Learning Git and GitHub][good-git-resources]
  - [Git Basics](https://github.com/PowerShell/PowerShell/blob/master/docs/git/basics.md): install and getting started
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/): step-by-step instructions of GitHub Flow

## Opening issues or submitting feature requests

If you are facing issues with either the PowerShell module or the VSCode extension you can open a [new issue](https://github.com/Azure/azure-powershell-migration/issues/new).
It is a best practice to search through existing issues if the issue has not been already been reported. If this is the case, vote on the issue to help prioritizing the work.

## Writing and improving documentation

Create a [fork of this repo][working-with-forks] to your account, create a new branch on your fork, edit the content, then submit a Pull Request.
More details on how to [create a Pull Request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request)

## Code contribution

### Code editor

We recommend that you use [Visual Studio Code](https://docs.microsoft.com/dotnet/core/tutorials/with-visual-studio-code)

### Setup your local environment

- We use [Pester v 4.10.1](https://www.powershellgallery.com/packages/Pester/4.10.1) for the tests. If not already present, you need to install it `Install-Module -Name Pester -RequiredVersion 4.10.1`
- Create a [fork of this repo][working-with-forks] to you own account.
- Clone your fork locally.

### Writing code

> **IMPORTANT:** If you are writting code to submit a feature request, ensure that you have submited a feature request before and it has been accepted.

- Launch VSCode and open the `powershell-module` folder instead of each individual file.
  Alternatively, from a prompt, navigate to `<your_path>\azure-powershell-migration\powershell-module` directory and type `code .`

- New features must have unit tests and supporting documentation in order to be accepted.
  
- To run your tests locally you need to add the path to the module directory `<your_path>\azure-powershell-migration\powershell-module` to the environment variable `$env:PSModulePath`. 

  Run your test with `Invoke-Pester -TestName "Name_of_your_test"`

- Any resources or code that may also be used for the VSCode extension should be placed in the `common` folder at the root of this repository.

Further reading:

- [Writting tests with Pester](https://pester.dev/docs/quick-start#creating-a-pester-test)
- [Introduction to Pester](https://dev.to/omiossec/unit-testing-in-powershell-introduction-to-pester-1de7)
- [Pester source code](https://github.com/pester/Pester/tree/4.10.1)

### Building and publishing

The owners of the repository own the publication process.
After a PR has been accepted and merged we will publish a revision of the module to the PowerShell gallery.

We will indicate in the PR when the module will be published using milestones.

## Contributor License Agreement (CLA)

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

[working-with-forks]: (https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/working-with-forks)