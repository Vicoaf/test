param(
    [Parameter(Mandatory = $true)]
    [string]$Agency,

    [Parameter(Mandatory = $true)]
    [string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$SchemaPath = Join-Path $Agency "config\schemas\proxtel-provider-adapter.schema.json"
$CasesPath = Join-Path $TestsRoot "adapter-contract-cases.json"

function Read-JsonStrict {

    param([string]$Path)

    $Raw = [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($false,$true)
    )

    return $Raw | ConvertFrom-Json
}

function Test-JsonType {

    param(
        $Value,
        [string]$TypeName
    )

    switch ($TypeName) {

        "null" {
            return ($null -eq $Value)
        }

        "object" {
            return ($Value -is [PSCustomObject])
        }

        "array" {
            return ($Value -is [System.Array])
        }

        "string" {
            return ($Value -is [string])
        }

        "boolean" {
            return ($Value -is [bool])
        }

        "integer" {

            return (
                $Value -is [byte] -or
                $Value -is [int16] -or
                $Value -is [int32] -or
                $Value -is [int64] -or
                $Value -is [uint16] -or
                $Value -is [uint32] -or
                $Value -is [uint64]
            )
        }

        "number" {

            return (
                (Test-JsonType $Value "integer") -or
                $Value -is [single] -or
                $Value -is [double] -or
                $Value -is [decimal]
            )
        }
    }

    return $false
}

function Test-JsonNode {

    param(
        $Value,
        $Schema,
        [string]$Path = "$"
    )

    $Errors = @()

    if ($null -ne $Schema.type) {

        $Types = @($Schema.type)
        $TypePass = $false

        foreach ($TypeName in $Types) {

            if (Test-JsonType $Value ([string]$TypeName)) {
                $TypePass = $true
                break
            }
        }

        if (-not $TypePass) {

            $Errors += "$Path`: type mismatch; expected [$($Types -join ', ')]"
            return $Errors
        }
    }

    if ($null -ne $Schema.const) {

        if ([string]$Value -cne [string]$Schema.const) {
            $Errors += "$Path`: value does not match const '$($Schema.const)'"
        }
    }

    if ($null -ne $Schema.enum) {

        $EnumValues = @($Schema.enum)

        if ($EnumValues -notcontains $Value) {
            $Errors += "$Path`: value '$Value' is not in enum [$($EnumValues -join ', ')]"
        }
    }

    if ($Value -is [string]) {

        if (
            $null -ne $Schema.pattern -and
            $Value -notmatch [string]$Schema.pattern
        ) {

            $Errors += "$Path`: string does not match pattern $($Schema.pattern)"
        }
    }

    if ($Value -is [System.Array]) {

        if (
            $null -ne $Schema.minItems -and
            $Value.Count -lt [int]$Schema.minItems
        ) {

            $Errors += "$Path`: expected at least $($Schema.minItems) items"
        }

        if ($null -ne $Schema.items) {

            for ($Index = 0; $Index -lt $Value.Count; $Index++) {

                $Errors += @(
                    Test-JsonNode `
                        -Value $Value[$Index] `
                        -Schema $Schema.items `
                        -Path "$Path[$Index]"
                )
            }
        }
    }

    if ($Value -is [PSCustomObject]) {

        $PropertyNames = @(
            $Value.PSObject.Properties.Name
        )

        foreach ($RequiredName in @($Schema.required)) {

            if ($PropertyNames -notcontains [string]$RequiredName) {
                $Errors += "$Path`: missing required property '$RequiredName'"
            }
        }

        if ($Schema.additionalProperties -eq $false) {

            $AllowedNames = @(
                $Schema.properties.PSObject.Properties.Name
            )

            foreach ($PropertyName in $PropertyNames) {

                if ($AllowedNames -notcontains $PropertyName) {
                    $Errors += "$Path`: unexpected property '$PropertyName'"
                }
            }
        }

        foreach ($Property in $Value.PSObject.Properties) {

            $ChildSchemaProperty = $Schema.properties.PSObject.Properties[$Property.Name]

            if ($null -ne $ChildSchemaProperty) {

                $Errors += @(
                    Test-JsonNode `
                        -Value $Property.Value `
                        -Schema $ChildSchemaProperty.Value `
                        -Path "$Path.$($Property.Name)"
                )
            }
        }
    }

    return $Errors
}

function Test-AdapterSemanticInvariants {

    param($Adapter)

    $Errors = @()

    if (
        $Adapter.safety.dangerous_bypass_forbidden -ne $true
    ) {
        $Errors += "$.safety: dangerous_bypass_forbidden must be true"
    }

    if (
        $Adapter.safety.production_first_test_allowed -ne $false
    ) {
        $Errors += "$.safety: production_first_test_allowed must be false"
    }

    if (
        $Adapter.lifecycle.state -eq "approved" -and
        $Adapter.lifecycle.execution_status -eq "not-executed"
    ) {
        $Errors += "$.lifecycle: approved adapter cannot remain not-executed"
    }

    return $Errors
}

$Schema = Read-JsonStrict -Path $SchemaPath
$CasesParsed = Read-JsonStrict -Path $CasesPath

$Cases = @()

foreach ($Item in @($CasesParsed)) {

    if ($Item -is [System.Array]) {

        foreach ($Nested in $Item) {
            $Cases += $Nested
        }
    }
    else {
        $Cases += $Item
    }
}

if ($Cases.Count -ne 9) {
    throw "Expected 9 adapter contract cases. Found=$($Cases.Count)"
}

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL PROVIDER ADAPTER CONTRACT TESTS"
Write-Host "============================================================"

$Passed = 0
$Failed = 0

foreach ($Case in $Cases) {

    $FixturePath = Join-Path $TestsRoot ([string]$Case.file)

    $Adapter = Read-JsonStrict -Path $FixturePath

    $Errors = @(
        Test-JsonNode `
            -Value $Adapter `
            -Schema $Schema
    )

    $Errors += @(
        Test-AdapterSemanticInvariants `
            -Adapter $Adapter
    )

    $ActualValid = ($Errors.Count -eq 0)
    $ExpectedValid = [bool]$Case.expected_valid

    if ($ActualValid -eq $ExpectedValid) {

        Write-Host ("[PASS] {0} | expected={1} actual={2}" -f $Case.id,$ExpectedValid,$ActualValid) -ForegroundColor Green

        foreach ($ErrorText in $Errors) {
            Write-Host "       $ErrorText"
        }

        $Passed++
    }
    else {

        Write-Host ("[FAIL] {0} | expected={1} actual={2}" -f $Case.id,$ExpectedValid,$ActualValid) -ForegroundColor Red

        foreach ($ErrorText in $Errors) {
            Write-Host "       $ErrorText"
        }

        $Failed++
    }
}

Write-Host ""
Write-Host "ADAPTER_CASES=$($Cases.Count)"
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"

if ($Failed -gt 0) {
    throw "PROVIDER ADAPTER CONTRACT TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL PROVIDER ADAPTER CONTRACT TESTS PASSED" -ForegroundColor Green