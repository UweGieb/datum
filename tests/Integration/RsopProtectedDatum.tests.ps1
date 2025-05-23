using module datum

$here = $PSScriptRoot

$global:ErrorActionPreference = 'Stop' #This is the default in Azure pipelines, but not in local tests
Remove-Module -Name datum

BeforeDiscovery {
    Import-Module -Name datum

    $script:datumPath = Join-Path -Path $here -ChildPath '.\assets\DscWorkshopConfigData\Datum.yml' -Resolve
    Write-Host "Loading datum from '$datumPath'"
    $script:datum = New-DatumStructure -DefinitionFile $datumPath

    $script:allNodes = $datum.AllNodes.Dev.psobject.Properties | ForEach-Object {
        $node = $Datum.AllNodes.Dev.($_.Name)
        (@{} + $Node)
    }

    $script:configurationData = @{
        AllNodes = $allNodes
        Datum    = $datum
    }

    $script:rsopPath = Join-Path -Path $BuildModuleOutput -ChildPath RSOP
    $script:rsopWithSourcePath = Join-Path -Path $BuildModuleOutput -ChildPath RsopWithSource
    mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
}

Describe "Datum Handler tests based on 'DscWorkshopConfigData' test data" {

    Context 'Accessing credentials with the correct key' {

        It "The property 'SomeWorkingCredential' is a 'PSCredential' object" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential | Should -BeOfType [pscredential]
        }

        It "The username in 'SomeWorkingCredential' is 'contoso\install'" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential.UserName | Should -Be 'contoso\install'
        }

        foreach ($node in $configurationData.AllNodes) {
            $script:rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopWithSourcePath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            It "The domain join credentials for node '$($node.NodeName)' could be accessed" {

                $rsop.ComputerSettings.Credential | Should -BeOfType [pscredential]

            }
        }
    }

    Context 'Accessing credentials with the wrong key' {

        It "The property 'SomeNonWorkingCredential' is a string like '[ENC*]'" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml" -ErrorAction Stop
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeNonWorkingCredential | Should -Belike '`[ENC=*'
        }
    }
}
