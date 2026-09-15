param(
    [Parameter(Mandatory = $true)]
    [string]$Agency,

    [Parameter(Mandatory = $true)]
    [string]$TestsRoot
)

$ErrorActionPreference = "Stop"

$SkillSchemaPath = Join-Path `
    $Agency `
    "config\schemas\proxtel-skill.schema.json"

$AuditSchemaPath = Join-Path `
    $Agency `
    "config\schemas\proxtel-skill-audit.schema.json"

$CasesPath = Join-Path `
    $TestsRoot `
    "contract-cases.json"


function Read-JsonStrict {

    param(
        [string]$Path
    )

    $Raw = [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new(
            $false,
            $true
        )
    )

    return $Raw | ConvertFrom-Json
}


function Test-ValueType {

    param(
        $Value,
        [string]$TypeName
    )

    switch ($TypeName) {

        "null" {
            return ($null -eq $Value)
        }

        "string" {
            return ($Value -is [string])
        }

        "boolean" {
            return ($Value -is [bool])
        }

        "array" {
            return (
                $null -ne $Value -and
                $Value -is [System.Array]
            )
        }

        "object" {
            return (
                $null -ne $Value -and
                $Value -is [PSCustomObject]
            )
        }

        "integer" {

            return (
                $Value -is [byte]   -or
                $Value -is [sbyte]  -or
                $Value -is [int16]  -or
                $Value -is [uint16] -or
                $Value -is [int32]  -or
                $Value -is [uint32] -or
                $Value -is [int64]  -or
                $Value -is [uint64]
            )
        }

        "number" {

            if (
                Test-ValueType `
                    -Value $Value `
                    -TypeName "integer"
            ) {
                return $true
            }

            return (
                $Value -is [single]  -or
                $Value -is [double]  -or
                $Value -is [decimal]
            )
        }

        default {
            throw "Unsupported schema type: $TypeName"
        }
    }
}


function Resolve-LocalRef {

    param(
        [string]$Reference,
        $RootSchema
    )

    if (
        $Reference -notmatch '^#/\$defs/(.+)$'
    ) {
        throw "Unsupported reference: $Reference"
    }

    $Name = $Matches[1]

    $Property = `
        $RootSchema.'$defs'.PSObject.Properties[$Name]

    if ($null -eq $Property) {
        throw "Unknown schema definition: $Name"
    }

    return $Property.Value
}


function Test-JsonNode {

    param(
        $Value,
        $Schema,
        $RootSchema,
        [string]$Path = '$'
    )

    if ($null -eq $Schema) {
        return
    }

    $SchemaProperties = @(
        $Schema.PSObject.Properties.Name
    )

    # --------------------------------------------------------
    # $ref
    # --------------------------------------------------------

    if ($SchemaProperties -contains '$ref') {

        $Resolved = Resolve-LocalRef `
            -Reference $Schema.'$ref' `
            -RootSchema $RootSchema

        Test-JsonNode `
            -Value $Value `
            -Schema $Resolved `
            -RootSchema $RootSchema `
            -Path $Path

        return
    }

    # --------------------------------------------------------
    # type
    # --------------------------------------------------------

    if ($SchemaProperties -contains "type") {

        $Types = @(
            $Schema.type
        )

        $TypePass = $false

        foreach ($TypeName in $Types) {

            if (
                Test-ValueType `
                    -Value $Value `
                    -TypeName ([string]$TypeName)
            ) {
                $TypePass = $true
                break
            }
        }

        if (-not $TypePass) {

            Write-Output (
                "{0}: type mismatch. Expected [{1}]" -f `
                $Path,
                ($Types -join ", ")
            )

            return
        }
    }

    if ($null -eq $Value) {
        return
    }

    # --------------------------------------------------------
    # const
    # --------------------------------------------------------

    if ($SchemaProperties -contains "const") {

        if (
            [string]$Value -ne
            [string]$Schema.const
        ) {

            Write-Output (
                "{0}: expected const '{1}'" -f `
                $Path,
                $Schema.const
            )
        }
    }

    # --------------------------------------------------------
    # enum
    # --------------------------------------------------------

    if ($SchemaProperties -contains "enum") {

        $EnumPass = $false

        foreach ($Allowed in @($Schema.enum)) {

            if (
                [string]$Value -ceq
                [string]$Allowed
            ) {
                $EnumPass = $true
                break
            }
        }

        if (-not $EnumPass) {

            Write-Output (
                "{0}: value '{1}' is not in enum [{2}]" -f `
                $Path,
                $Value,
                (@($Schema.enum) -join ", ")
            )
        }
    }

    # --------------------------------------------------------
    # string
    # --------------------------------------------------------

    if ($Value -is [string]) {

        if (
            $SchemaProperties -contains "minLength" -and
            $Value.Length -lt [int]$Schema.minLength
        ) {

            Write-Output (
                "{0}: string shorter than minLength {1}" -f `
                $Path,
                $Schema.minLength
            )
        }

        if (
            $SchemaProperties -contains "maxLength" -and
            $Value.Length -gt [int]$Schema.maxLength
        ) {

            Write-Output (
                "{0}: string longer than maxLength {1}" -f `
                $Path,
                $Schema.maxLength
            )
        }

        if (
            $SchemaProperties -contains "pattern" -and
            $Value -notmatch $Schema.pattern
        ) {

            Write-Output (
                "{0}: string does not match pattern {1}" -f `
                $Path,
                $Schema.pattern
            )
        }

        if (
            $SchemaProperties -contains "format" -and
            $Schema.format -eq "date-time"
        ) {

            $ParsedDate = [DateTimeOffset]::MinValue

            $DatePass = [DateTimeOffset]::TryParse(
                $Value,
                [ref]$ParsedDate
            )

            if (-not $DatePass) {

                Write-Output (
                    "{0}: invalid date-time" -f $Path
                )
            }
        }
    }

    # --------------------------------------------------------
    # numeric minimum / maximum
    # --------------------------------------------------------

    $IsNumber = (
        Test-ValueType `
            -Value $Value `
            -TypeName "number"
    )

    if ($IsNumber) {

        if (
            $SchemaProperties -contains "minimum" -and
            [double]$Value -lt [double]$Schema.minimum
        ) {

            Write-Output (
                "{0}: value below minimum {1}" -f `
                $Path,
                $Schema.minimum
            )
        }

        if (
            $SchemaProperties -contains "maximum" -and
            [double]$Value -gt [double]$Schema.maximum
        ) {

            Write-Output (
                "{0}: value above maximum {1}" -f `
                $Path,
                $Schema.maximum
            )
        }
    }

    # --------------------------------------------------------
    # arrays
    # --------------------------------------------------------

    if ($Value -is [System.Array]) {

        if (
            $SchemaProperties -contains "minItems" -and
            $Value.Count -lt [int]$Schema.minItems
        ) {

            Write-Output (
                "{0}: fewer items than minItems {1}" -f `
                $Path,
                $Schema.minItems
            )
        }

        if (
            $SchemaProperties -contains "uniqueItems" -and
            $Schema.uniqueItems -eq $true
        ) {

            $Serialized = @(
                $Value |
                ForEach-Object {
                    $_ |
                    ConvertTo-Json `
                        -Depth 50 `
                        -Compress
                }
            )

            if (
                @(
                    $Serialized |
                    Sort-Object -Unique
                ).Count -ne
                $Serialized.Count
            ) {

                Write-Output (
                    "{0}: duplicate array items" -f $Path
                )
            }
        }

        if ($SchemaProperties -contains "items") {

            for (
                $Index = 0;
                $Index -lt $Value.Count;
                $Index++
            ) {

                Test-JsonNode `
                    -Value $Value[$Index] `
                    -Schema $Schema.items `
                    -RootSchema $RootSchema `
                    -Path "$Path[$Index]"
            }
        }
    }

    # --------------------------------------------------------
    # objects
    # --------------------------------------------------------

    if ($Value -is [PSCustomObject]) {

        $ValueProperties = @(
            $Value.PSObject.Properties.Name
        )

        if ($SchemaProperties -contains "required") {

            foreach ($Required in @($Schema.required)) {

                if (
                    $ValueProperties -notcontains
                    [string]$Required
                ) {

                    Write-Output (
                        "{0}: missing required property '{1}'" -f `
                        $Path,
                        $Required
                    )
                }
            }
        }

        if ($SchemaProperties -contains "properties") {

            foreach (
                $PropertySchema
                in $Schema.properties.PSObject.Properties
            ) {

                $PropertyName = $PropertySchema.Name

                if (
                    $ValueProperties -contains
                    $PropertyName
                ) {

                    $ChildValue = `
                        $Value.PSObject.Properties[
                            $PropertyName
                        ].Value

                    Test-JsonNode `
                        -Value $ChildValue `
                        -Schema $PropertySchema.Value `
                        -RootSchema $RootSchema `
                        -Path "$Path.$PropertyName"
                }
            }
        }

        if (
            $SchemaProperties -contains
            "additionalProperties" -and
            $Schema.additionalProperties -eq $false
        ) {

            $Allowed = @()

            if (
                $SchemaProperties -contains
                "properties"
            ) {

                $Allowed = @(
                    $Schema.properties.PSObject.Properties.Name
                )
            }

            foreach ($ActualProperty in $ValueProperties) {

                if (
                    $Allowed -notcontains
                    $ActualProperty
                ) {

                    Write-Output (
                        "{0}: unexpected property '{1}'" -f `
                        $Path,
                        $ActualProperty
                    )
                }
            }
        }
    }
}


function Test-ProxtelSemanticInvariants {

    param(
        $Object
    )

    if (
        $Object.kind -eq
        "proxtel-skill-audit"
    ) {

        $Mode = `
            $Object.metrics.token_measurement

        $Tokens = `
            $Object.metrics.actual_tokens

        if (
            $Mode -eq "not-measured" -and
            $null -ne $Tokens
        ) {

            Write-Output (
                '$.metrics: actual_tokens must be null when token_measurement=not-measured'
            )
        }

        if (
            $Mode -eq "actual" -and
            $null -eq $Tokens
        ) {

            Write-Output (
                '$.metrics: actual_tokens is required when token_measurement=actual'
            )
        }
    }
}


# ============================================================
# LOAD
# ============================================================

$SkillSchema = Read-JsonStrict `
    -Path $SkillSchemaPath

$AuditSchema = Read-JsonStrict `
    -Path $AuditSchemaPath

$CasesParsed = Read-JsonStrict `
    -Path $CasesPath

$Cases = New-Object System.Collections.ArrayList

foreach ($Item in @($CasesParsed)) {

    if ($Item -is [System.Array]) {

        foreach ($NestedItem in $Item) {

            [void]$Cases.Add($NestedItem)
        }
    }

    if ($Item -isnot [System.Array]) {

        [void]$Cases.Add($Item)
    }
}

if ($Cases.Count -ne 8) {

    throw "Expected 8 contract cases. Found=$($Cases.Count)"
}

foreach ($CaseCheck in $Cases) {

    if ($null -eq $CaseCheck) {
        throw "Null contract case detected."
    }

    if ($null -eq $CaseCheck.PSObject.Properties["id"]) {
        throw "Contract case missing id."
    }

    if ($null -eq $CaseCheck.PSObject.Properties["file"]) {
        throw "Contract case missing file."
    }

    if ($null -eq $CaseCheck.PSObject.Properties["schema"]) {
        throw "Contract case missing schema."
    }

    if ($CaseCheck.id -isnot [string]) {
        throw "Contract case id must be string."
    }

    if ($CaseCheck.file -isnot [string]) {
        throw "Contract case file must be string. Case=$($CaseCheck.id)"
    }

    if ($CaseCheck.schema -isnot [string]) {
        throw "Contract case schema must be string. Case=$($CaseCheck.id)"
    }
}

Write-Host "CASES_LOADED=$($Cases.Count)"

# ============================================================
# RUN
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL CONTRACT TEST RUNNER"
Write-Host "============================================================"

$Passed = 0
$Failed = 0

foreach ($Case in $Cases) {

    $FixturePath = Join-Path `
        $TestsRoot `
        $Case.file

    $Object = Read-JsonStrict `
        -Path $FixturePath

    if ($Case.schema -eq "skill") {

        $Schema = $SkillSchema
    }
    elseif ($Case.schema -eq "audit") {

        $Schema = $AuditSchema
    }
    else {

        throw "Unknown schema type: $($Case.schema)"
    }

    $Errors = @(
        Test-JsonNode `
            -Value $Object `
            -Schema $Schema `
            -RootSchema $Schema

        Test-ProxtelSemanticInvariants `
            -Object $Object
    )

    $ActualValid = (
        $Errors.Count -eq 0
    )

    $Expected = [bool]$Case.expect_valid

    if ($ActualValid -eq $Expected) {

        Write-Host (
            "[PASS] {0} | expected={1} actual={2}" -f `
            $Case.id,
            $Expected,
            $ActualValid
        ) -ForegroundColor Green

        $Passed++
    }
    else {

        Write-Host (
            "[FAIL] {0} | expected={1} actual={2}" -f `
            $Case.id,
            $Expected,
            $ActualValid
        ) -ForegroundColor Red

        $Failed++
    }

    foreach ($ErrorText in $Errors) {
        Write-Host "       $ErrorText"
    }
}

Write-Host ""
Write-Host "PASSED=$Passed"
Write-Host "FAILED=$Failed"
Write-Host "TOTAL=$($Passed + $Failed)"

if ($Failed -gt 0) {
    throw "CONTRACT TEST FAILURE"
}

Write-Host ""
Write-Host "[PASS] ALL CONTRACT TESTS PASSED" `
    -ForegroundColor Green