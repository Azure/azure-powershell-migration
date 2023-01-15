<!--
    Please leave this section at the top of the change log.

    Changes for the upcoming release should go under the section titled "Upcoming Release", and should adhere to the following format:

    ## Upcoming Release
    * Overview of change #1
        - Additional information about change #1
    * Overview of change #2
        - Additional information about change #2
        - Additional information about change #2
    * Overview of change #3
    * Overview of change #4
        - Additional information about change #4

    ## YYYY.MM.DD - Version X.Y.Z (Previous Release)
    * Overview of change #1
        - Additional information about change #1
-->
## Upcoming Release

## 1.1.4
* Upgraded Az Version to 9.3.0

## 1.1.3
* Upgrade Az version to 8.0.0

## 1.1.2
* Upgrade Az version to 6.1.0

## 1.1.1
* Fixed a bug in Invoke-AzUpgradeModulePlan where dynamic parameters are incorrectly updated (issue #81).

## 1.1.0
* Upgrade Az version to 5.6.0
* Fixed a bug where New-AzUpgradeModulePlan throws errors when analyzing hashtable code (issue #73).
* Updated scanning results for Az cmdlets that implement dynamic parameters to use clearer warnings.
* Updated Get-AzUpgradeCmdletSpec to improve performance.
* Updated quickstart guide to remove outdated guidance on splatted parameter detection.

## 1.0.0
* General availability of 'Az.Tools.Migration' module
* Upgraded Az version to 5.2

## 0.1.0
* The first preview release
