Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

BeforeDiscovery {
    $here = $PSScriptRoot
    $script:projectPath = "$here\..\.." | Convert-Path


    $script:testCases = @(
        @{
            InputString          = 'Hello World' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
            Depth                = 0
            Key                  = 'SomeKey'
            RelativeFilePath     = 'DscWorkshopConfigData\Datum'
            AddSourceInformation = $false
        }
        @{
            InputString          = 'Hello World' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
            Depth                = 0
            Key                  = 'SomeKey'
            RelativeFilePath     = 'DscWorkshopConfigData\Datum'
            AddSourceInformation = $true
        }
    )
}
    Describe 'Get-RsopValueString' {

        It "Result string for '<InputString>' should match the expectations'." -ForEach $testCases {
            param ($InputString, $Depth, $Key, $IsArrayValue, $AddSourceInformation, $RelativeFilePath)

            #TODo: $resultString has after "Hello world" the path after blance spaces, but InputString has not. All keys have the same values as in pester 4, but resultstring is different.
            $resultString = Get-RsopValueString -InputString $InputString -Key $Key -Depth $Depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
            $resultString | Should -BeLike "$InputString*"
            if ($AddSourceInformation)
            {
                $resultString | Should -BeLike "*$RelativeFilePath"
            }
            else
            {
                $resultString | Should -Not -BeLike "*$RelativeFilePath"
            }

            $resultString | Should -BeOfType [string]
        }

    }

}
