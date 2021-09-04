@{
    CustomRulePath = @(
        '.\PSA_custom_Rules\Alias\avoidAlias.psm1'
        '.\PSA_custom_Rules\BreakingChange\upcomingBreakingChange.psm1'
    )
    

    IncludeRules   = @(
        'Measure-*'
    )
}