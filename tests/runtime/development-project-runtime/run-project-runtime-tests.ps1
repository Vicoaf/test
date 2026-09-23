[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StageRoot,

    [Parameter(Mandatory = $true)]
    [string]$AgencyRoot
)

$ErrorActionPreference = 'Stop'

function Read-JsonFile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (
        Get-Content `
            -LiteralPath $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json
    )
}

function Quote-Ps {

    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return (
        "'" +
        $Value.Replace(
            "'",
            "''"
        ) +
        "'"
    )
}

function Write-Fixture {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Fixture
    )

    New-Item `
        -ItemType Directory `
        -Path $Path `
        -Force |
        Out-Null

    if ($Fixture -ceq 'laravel-family') {

        [System.IO.File]::WriteAllText(
            (Join-Path $Path 'artisan'),
            "<?php`n"
        )

        [System.IO.File]::WriteAllText(
            (Join-Path $Path 'composer.json'),
            '{}'
        )

        [System.IO.File]::WriteAllText(
            (Join-Path $Path 'package.json'),
            '{}'
        )
    }
    elseif ($Fixture -ceq 'frontend-family') {

        [System.IO.File]::WriteAllText(
            (Join-Path $Path 'package.json'),
            '{}'
        )

        [System.IO.File]::WriteAllText(
            (Join-Path $Path 'vite.config.js'),
            'export default {};'
        )
    }
    elseif ($Fixture -ceq 'empty') {

        # Intentionally empty.
    }
    else {

        throw "Unsupported fixture [$Fixture]."
    }
}

function Invoke-Resolver {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolverPath,

        [Parameter(Mandatory = $true)]
        [string]$AgencyRoot,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$PolicyPath,

        [AllowNull()]
        [string]$ProjectType
    )

    $Command = (
        '& ' +
        (Quote-Ps $ResolverPath) +
        ' -AgencyRoot ' +
        (Quote-Ps $AgencyRoot) +
        ' -ProjectRoot ' +
        (Quote-Ps $ProjectRoot) +
        ' -PolicyPath ' +
        (Quote-Ps $PolicyPath)
    )

    if (
        -not [string]::IsNullOrWhiteSpace(
            $ProjectType
        )
    ) {

        $Command += (
            ' -ProjectType ' +
            (Quote-Ps $ProjectType)
        )
    }

    $Encoded = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes(
            $Command
        )
    )

    $Psi = New-Object `
        System.Diagnostics.ProcessStartInfo

    $Psi.FileName = 'powershell.exe'

    $Psi.Arguments = (
        '-NoProfile -NonInteractive ' +
        '-ExecutionPolicy Bypass ' +
        '-EncodedCommand ' +
        $Encoded
    )

    $Psi.UseShellExecute = $false
    $Psi.CreateNoWindow = $true
    $Psi.RedirectStandardOutput = $true
    $Psi.RedirectStandardError = $true

    $Process = New-Object `
        System.Diagnostics.Process

    $Process.StartInfo = $Psi

    if (-not $Process.Start()) {
        throw 'Resolver child process could not start.'
    }

    $StdoutTask = `
        $Process.StandardOutput.ReadToEndAsync()

    $StderrTask = `
        $Process.StandardError.ReadToEndAsync()

    if (-not $Process.WaitForExit(30000)) {

        try {
            $Process.Kill()
        }
        catch {
        }

        throw 'Resolver child process timeout.'
    }

    return [PSCustomObject][ordered]@{
        exit_code = [int]$Process.ExitCode
        stdout = [string]$StdoutTask.Result
        stderr = [string]$StderrTask.Result
    }
}

$ResolverPath = Join-Path `
    $StageRoot `
    'scripts\development-project-runtime-resolver.ps1'

$PolicyPath = Join-Path `
    $StageRoot `
    'config\development-project-runtime-policy.json'

$CasesPath = Join-Path `
    $StageRoot `
    'tests\runtime\development-project-runtime\project-runtime-cases.json'

$Cases = Read-JsonFile `
    -Path $CasesPath

$Bundles = Read-JsonFile `
    -Path (
        Join-Path `
            $AgencyRoot `
            'config\skill-bundles.json'
    )

$ToolRegistry = Read-JsonFile `
    -Path (
        Join-Path `
            $AgencyRoot `
            'tools\registry\development-tools.json'
    )

$FixtureRoot = Join-Path `
    $env:LOCALAPPDATA `
    (
        'PROXTEL-AI-AGENCY\area-1.9\' +
        'm3-c-fix1-fixtures\' +
        [guid]::NewGuid().ToString('N')
    )

$CasePassCount = 0
$CaseFailureCount = 0

$ObservedAuxiliaryEdges = New-Object `
    'System.Collections.Generic.List[string]'

try {

    foreach ($Case in @($Cases.cases)) {

        $CaseRoot = Join-Path `
            $FixtureRoot `
            ([string]$Case.id)

        Write-Fixture `
            -Path $CaseRoot `
            -Fixture ([string]$Case.fixture)

        # PowerShell 5.1 parser-safe resolution:
        # resolve the nullable value BEFORE the function call.
        $CaseProjectType = $null

        if ($null -ne $Case.project_type) {

            $CaseProjectType = `
                [string]$Case.project_type
        }

        $Invocation = Invoke-Resolver `
            -ResolverPath $ResolverPath `
            -AgencyRoot $AgencyRoot `
            -ProjectRoot $CaseRoot `
            -PolicyPath $PolicyPath `
            -ProjectType $CaseProjectType

        if ($Invocation.exit_code -ne 0) {

            throw (
                "Case [$($Case.id)] resolver exit " +
                "[$($Invocation.exit_code)]. " +
                "stderr=[$($Invocation.stderr.Trim())]"
            )
        }

        if (
            [string]::IsNullOrWhiteSpace(
                $Invocation.stdout
            )
        ) {

            throw (
                "Case [$($Case.id)] produced no JSON."
            )
        }

        try {

            $Result = `
                $Invocation.stdout.Trim() |
                ConvertFrom-Json
        }
        catch {

            throw (
                "Case [$($Case.id)] invalid JSON output."
            )
        }

        if (
            [string]$Result.status -cne
            [string]$Case.expected_status
        ) {

            throw (
                "Case [$($Case.id)] status mismatch. " +
                "expected=[$($Case.expected_status)] " +
                "actual=[$($Result.status)]"
            )
        }

        foreach ($Property in @(
            'tool_execution_allowed',
            'provider_execution_allowed',
            'model_execution_allowed',
            'production_mutation_allowed',
            'database_mutation_allowed',
            'external_api_mutation_allowed'
        )) {

            if ([bool]$Result.safety.$Property) {

                throw (
                    "Case [$($Case.id)] unsafe flag " +
                    "[$Property]."
                )
            }
        }

        if (
            [string]$Case.expected_status -ceq
            'resolved'
        ) {

            if (
                [string]$Result.project.project_type -cne
                [string]$Case.expected_project_type
            ) {

                throw (
                    "Case [$($Case.id)] project type mismatch."
                )
            }

            $TemplatePath = Join-Path `
                $AgencyRoot `
                (
                    'templates\' +
                    [string]$Case.expected_project_type +
                    '\template.json'
                )

            $Template = Read-JsonFile `
                -Path $TemplatePath

            if (
                @($Result.lanes).Count -ne
                @($Template.primary_lanes).Count
            ) {

                throw (
                    "Case [$($Case.id)] lane count mismatch."
                )
            }

            $BundleProperty = `
                $Bundles.PSObject.Properties[
                    [string]$Case.expected_project_type
                ]

            if ($null -eq $BundleProperty) {

                throw (
                    "Case [$($Case.id)] bundle missing."
                )
            }

            if (
                @($Result.skills).Count -ne
                @($BundleProperty.Value).Count
            ) {

                throw (
                    "Case [$($Case.id)] Skill count mismatch."
                )
            }

            if (
                @($Result.tools).Count -ne
                @($Template.compatible_tools).Count
            ) {

                throw (
                    "Case [$($Case.id)] Tool count mismatch."
                )
            }

            foreach ($ResolvedTool in @($Result.tools)) {

                $ToolId = [string]$ResolvedTool.id

                $RegistryMatches = @(
                    @($ToolRegistry.tools) |
                    Where-Object {
                        [string]$_.id -ceq
                        $ToolId
                    }
                )

                if ($RegistryMatches.Count -ne 1) {

                    throw (
                        "Case [$($Case.id)] " +
                        "Tool [$ToolId] missing."
                    )
                }

                $ExpectedOverlap = @(
                    @($RegistryMatches[0].capability_lanes) |
                    Where-Object {
                        @($Template.primary_lanes) -ccontains
                        [string]$_
                    }
                )

                $ExpectedRelationship = 'direct-lane'

                if ($ExpectedOverlap.Count -eq 0) {

                    $ExpectedRelationship = `
                        'template-authorized-auxiliary'
                }

                if (
                    [string]$ResolvedTool.relationship -cne
                    $ExpectedRelationship
                ) {

                    throw (
                        "Case [$($Case.id)] " +
                        "Tool [$ToolId] relationship mismatch. " +
                        "expected=[$ExpectedRelationship] " +
                        "actual=[$($ResolvedTool.relationship)]"
                    )
                }

                if ([bool]$ResolvedTool.execution_allowed) {

                    throw (
                        "Case [$($Case.id)] " +
                        "Tool execution unexpectedly allowed."
                    )
                }

                if (
                    $ExpectedRelationship -ceq
                    'template-authorized-auxiliary'
                ) {

                    $AuxEdge = (
                        [string]$Case.expected_project_type +
                        '|' +
                        $ToolId
                    )

                    if (-not $ObservedAuxiliaryEdges.Contains(
                        $AuxEdge
                    )) {

                        $ObservedAuxiliaryEdges.Add(
                            $AuxEdge
                        )
                    }
                }
            }

            if (
                [string]$Result.workflow.id -cne
                'development-software-delivery'
            ) {

                throw (
                    "Case [$($Case.id)] workflow mismatch."
                )
            }
        }
        else {

            if ($null -ne $Result.template) {
                throw "Blocked case [$($Case.id)] returned template."
            }

            if (@($Result.lanes).Count -ne 0) {
                throw "Blocked case [$($Case.id)] returned lanes."
            }

            if (@($Result.skills).Count -ne 0) {
                throw "Blocked case [$($Case.id)] returned Skills."
            }

            if (@($Result.tools).Count -ne 0) {
                throw "Blocked case [$($Case.id)] returned Tools."
            }

            if ($null -ne $Result.workflow) {
                throw "Blocked case [$($Case.id)] returned workflow."
            }

            if ($null -ne $Result.project.project_type) {

                throw (
                    "Blocked case [$($Case.id)] unexpectedly " +
                    'resolved a project type.'
                )
            }
        }

        $CasePassCount++

        Write-Host (
            "RUNTIME_CASE_PASS=[$($Case.id)] " +
            "status=[$($Result.status)]"
        )
    }

    $ExpectedAuxiliaryEdges = @(
        'website|api-tester',
        'landing-page|api-tester'
    )

    Write-Host (
        "OBSERVED_AUXILIARY_EDGE_COUNT=" +
        "$($ObservedAuxiliaryEdges.Count)"
    )

    if ($ObservedAuxiliaryEdges.Count -ne 2) {

        throw (
            'Expected exactly two observed ' +
            'auxiliary Tool edges.'
        )
    }

    foreach ($ExpectedEdge in $ExpectedAuxiliaryEdges) {

        if (-not $ObservedAuxiliaryEdges.Contains(
            $ExpectedEdge
        )) {

            throw (
                "Expected auxiliary edge missing " +
                "[$ExpectedEdge]."
            )
        }

        Write-Host (
            "AUXILIARY_EDGE_PASS=[$ExpectedEdge]"
        )
    }

    # --------------------------------------------------------
    # Determinism
    # --------------------------------------------------------

    $DeterminismRoot = Join-Path `
        $FixtureRoot `
        'determinism-website'

    Write-Fixture `
        -Path $DeterminismRoot `
        -Fixture 'empty'

    $RunA = Invoke-Resolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $AgencyRoot `
        -ProjectRoot $DeterminismRoot `
        -PolicyPath $PolicyPath `
        -ProjectType 'website'

    $RunB = Invoke-Resolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $AgencyRoot `
        -ProjectRoot $DeterminismRoot `
        -PolicyPath $PolicyPath `
        -ProjectType 'website'

    if ($RunA.exit_code -ne 0) {
        throw 'Determinism run A failed.'
    }

    if ($RunB.exit_code -ne 0) {
        throw 'Determinism run B failed.'
    }

    if (
        $RunA.stdout.Trim() -cne
        $RunB.stdout.Trim()
    ) {

        throw 'Resolver output is not deterministic.'
    }

    Write-Host '[PASS] DETERMINISTIC_OUTPUT=BYTE-IDENTICAL'
}
finally {

    if (
        Test-Path `
            -LiteralPath $FixtureRoot `
            -PathType Container
    ) {

        Remove-Item `
            -LiteralPath $FixtureRoot `
            -Recurse `
            -Force
    }
}

Write-Host "RUNTIME_CASE_PASS_COUNT=$CasePassCount"
Write-Host "RUNTIME_CASE_FAILURE_COUNT=$CaseFailureCount"

if ($CasePassCount -ne 9) {
    throw 'Expected 9 runtime case PASS results.'
}

if ($CaseFailureCount -ne 0) {
    throw 'Runtime case failures detected.'
}

Write-Host '[PASS] OFFLINE_RUNTIME_CASES=9/9'
Write-Host '[PASS] AUXILIARY_TOOL_RELATIONSHIPS=2/2'
Write-Host '[PASS] FIXTURE_ROOT_REMOVED=True'
# ============================================================
# SECURITY REGRESSION TESTS — M3-D-FIX1

function Invoke-SecurityResolver {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolverPath,

        [Parameter(Mandatory = $true)]
        [string]$AgencyRoot,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$PolicyPath,

        [AllowNull()]
        [string]$ProjectType
    )

    $BaseInvocation = Invoke-Resolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $AgencyRoot `
        -ProjectRoot $ProjectRoot `
        -PolicyPath $PolicyPath `
        -ProjectType $ProjectType

    $ParsedResult = $null

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$BaseInvocation.stdout
        )
    ) {

        try {

            $ParsedResult = `
                ([string]$BaseInvocation.stdout).
                Trim() |
                ConvertFrom-Json
        }
        catch {

            throw (
                'Security resolver returned invalid JSON. ' +
                'stdout=[' +
                ([string]$BaseInvocation.stdout).Trim() +
                '] stderr=[' +
                ([string]$BaseInvocation.stderr).Trim() +
                ']'
            )
        }
    }

    return [PSCustomObject][ordered]@{

        exit_code =
            [int]$BaseInvocation.exit_code

        stdout =
            [string]$BaseInvocation.stdout

        stderr =
            [string]$BaseInvocation.stderr

        result =
            $ParsedResult
    }
}

# ============================================================

function Write-SecurityJson {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        $Object
    )

    $Parent = Split-Path `
        -Parent $Path

    if (-not (
        Test-Path `
            -LiteralPath $Parent `
            -PathType Container
    )) {

        New-Item `
            -ItemType Directory `
            -Path $Parent `
            -Force |
            Out-Null
    }

    $Json = $Object |
        ConvertTo-Json `
            -Depth 70

    [System.IO.File]::WriteAllText(
        $Path,
        ($Json + "`n"),
        (
            New-Object `
                System.Text.UTF8Encoding($false)
        )
    )
}

function Copy-SecurityAgencyFile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Relative,

        [Parameter(Mandatory = $true)]
        [string]$TargetAgency
    )

    $Source = Join-Path `
        $AgencyRoot `
        $Relative.Replace('/','\')

    $Target = Join-Path `
        $TargetAgency `
        $Relative.Replace('/','\')

    $Parent = Split-Path `
        -Parent $Target

    if (-not (
        Test-Path `
            -LiteralPath $Parent `
            -PathType Container
    )) {

        New-Item `
            -ItemType Directory `
            -Path $Parent `
            -Force |
            Out-Null
    }

    [System.IO.File]::Copy(
        $Source,
        $Target,
        $true
    )
}

function Assert-SecurityBlocked {

    param(
        [Parameter(Mandatory = $true)]
        $Invocation,

        [Parameter(Mandatory = $true)]
        [string]$CaseId
    )

    if ($Invocation.exit_code -eq 0) {

        throw (
            "Security case [$CaseId] unexpectedly " +
            'returned exit code 0.'
        )
    }

    if ($null -eq $Invocation.result) {

        throw (
            "Security case [$CaseId] did not return " +
            'structured JSON.'
        )
    }

    if (
        [string]$Invocation.result.status -ceq
        'resolved'
    ) {

        throw (
            "Security case [$CaseId] unexpectedly resolved."
        )
    }

    if (
        [string]$Invocation.result.status -cne
        'blocked-unresolved'
    ) {

        throw (
            "Security case [$CaseId] unexpected status " +
            "[$($Invocation.result.status)]."
        )
    }

    if (@($Invocation.result.lanes).Count -ne 0) {
        throw "Security case [$CaseId] returned lanes."
    }

    if (@($Invocation.result.skills).Count -ne 0) {
        throw "Security case [$CaseId] returned Skills."
    }

    if (@($Invocation.result.tools).Count -ne 0) {
        throw "Security case [$CaseId] returned Tools."
    }

    if ($null -ne $Invocation.result.workflow) {
        throw "Security case [$CaseId] returned workflow."
    }

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Invocation.result.
            evidence.resolver_error
        )
    ) {

        throw (
            "Security case [$CaseId] returned no " +
            'resolver_error evidence.'
        )
    }
}

$SecurityFixtureRoot = Join-Path `
    $env:LOCALAPPDATA `
    (
        'PROXTEL-AI-AGENCY\area-1.9\' +
        'm3-d-fix1-security-tests\' +
        [guid]::NewGuid().ToString('N')
    )

$SecurityShadowAgency = Join-Path `
    $SecurityFixtureRoot `
    'shadow-agency'

$SecurityEscapedRoot = Join-Path `
    $SecurityFixtureRoot `
    'escaped'

$SecurityProjectRoot = Join-Path `
    $SecurityFixtureRoot `
    'project'

$SecurityPassCount = 0
$SecurityFailureCount = 0

try {

    New-Item `
        -ItemType Directory `
        -Path $SecurityShadowAgency `
        -Force |
        Out-Null

    New-Item `
        -ItemType Directory `
        -Path $SecurityProjectRoot `
        -Force |
        Out-Null

    $SecurityFiles = @(
        'config/development-runtime-bindings.json',
        'config/skill-bundles.json',
        'tools/registry/development-tools.json',
        'agents/development/proxtel-development-orchestrator/agent.json',
        'workflows/development/software-delivery/workflow.json',
        'skills/_registry/skills-registry.json',
        'scripts/skill-source-resolver.ps1',
        'adapters/claude/adapter.json',
        'adapters/codex/adapter.json',
        'adapters/antigravity/adapter.json',
        'templates/website/template.json',
        'templates/landing-page/template.json',
        'templates/laravel/template.json',
        'templates/crm/template.json',
        'templates/saas/template.json'
    )

    foreach ($Relative in $SecurityFiles) {

        Copy-SecurityAgencyFile `
            -Relative $Relative `
            -TargetAgency $SecurityShadowAgency
    }

    $SecuritySubagentFiles = @(
        Get-ChildItem `
            -LiteralPath (
                Join-Path `
                    $AgencyRoot `
                    'agents\development'
            ) `
            -Filter 'subagent.json' `
            -File `
            -Recurse
    )

    if ($SecuritySubagentFiles.Count -ne 6) {

        throw (
            'Security fixture expected six Subagents.'
        )
    }

    foreach ($File in $SecuritySubagentFiles) {

        $Relative = (
            $File.FullName.Substring(
                $AgencyRoot.Length
            ).
            TrimStart('\').
            Replace('\','/')
        )

        Copy-SecurityAgencyFile `
            -Relative $Relative `
            -TargetAgency $SecurityShadowAgency
    }

    $SecurityPolicyPath = Join-Path `
        $StageRoot `
        'config\development-project-runtime-policy.json'

    # --------------------------------------------------------
    # Security baseline
    # --------------------------------------------------------

    $SecurityBaseline = Invoke-SecurityResolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $SecurityShadowAgency `
        -ProjectRoot $SecurityProjectRoot `
        -PolicyPath $SecurityPolicyPath `
        -ProjectType 'website'

    if ($SecurityBaseline.exit_code -ne 0) {

        throw (
            'Security baseline failed. stderr=[' +
            $SecurityBaseline.stderr.Trim() +
            ']'
        )
    }

    if (
        $null -eq $SecurityBaseline.result -or
        [string]$SecurityBaseline.result.status -cne
        'resolved'
    ) {

        throw 'Security baseline did not resolve.'
    }

    if (
        [string]$SecurityBaseline.result.
        evidence.authority_validation -cne
        'pass'
    ) {

        throw (
            'Security baseline did not report ' +
            'authority_validation=pass.'
        )
    }

    if (
        [int]$SecurityBaseline.result.
        evidence.authority_hash_count -ne 10
    ) {

        throw (
            'Security baseline authority hash count invalid.'
        )
    }

    Write-Host '[SECURITY_BASELINE_PASS] CANONICAL_SHADOW_ROUTE=RESOLVED'

    # --------------------------------------------------------
    # 1 - Authority file drift
    # --------------------------------------------------------

    $ShadowRuntimePath = Join-Path `
        $SecurityShadowAgency `
        'config\development-runtime-bindings.json'

    $TamperedRuntime = Read-JsonFile `
        -Path $ShadowRuntimePath

    $ArchitectureBinding = @(
        $TamperedRuntime.bindings |
        Where-Object {
            [string]$_.lane -ceq 'architecture'
        }
    )

    if ($ArchitectureBinding.Count -ne 1) {
        throw 'Architecture binding not unique.'
    }

    $ArchitectureBinding[0].
    preferred_provider = 'codex'

    Write-SecurityJson `
        -Path $ShadowRuntimePath `
        -Object $TamperedRuntime

    $AuthorityDrift = Invoke-SecurityResolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $SecurityShadowAgency `
        -ProjectRoot $SecurityProjectRoot `
        -PolicyPath $SecurityPolicyPath `
        -ProjectType 'website'

    Assert-SecurityBlocked `
        -Invocation $AuthorityDrift `
        -CaseId 'authority-hash-drift'

    $SecurityPassCount++

    Write-Host '[SECURITY_CASE_PASS] AUTHORITY_HASH_DRIFT=FAIL-CLOSED'

    Copy-SecurityAgencyFile `
        -Relative 'config/development-runtime-bindings.json' `
        -TargetAgency $SecurityShadowAgency

    # --------------------------------------------------------
    # 2 - Authority path escape
    # --------------------------------------------------------

    New-Item `
        -ItemType Directory `
        -Path $SecurityEscapedRoot `
        -Force |
        Out-Null

    [System.IO.File]::Copy(
        (
            Join-Path `
                $AgencyRoot `
                'config\development-runtime-bindings.json'
        ),
        (
            Join-Path `
                $SecurityEscapedRoot `
                'development-runtime-bindings.json'
        ),
        $true
    )

    $EscapePolicy = Read-JsonFile `
        -Path $SecurityPolicyPath

    $EscapePolicy.authorities.
    runtime_bindings = `
        '..\escaped\development-runtime-bindings.json'

    $EscapePolicyPath = Join-Path `
        $SecurityFixtureRoot `
        'policy-path-escape.json'

    Write-SecurityJson `
        -Path $EscapePolicyPath `
        -Object $EscapePolicy

    $PathEscape = Invoke-SecurityResolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $SecurityShadowAgency `
        -ProjectRoot $SecurityProjectRoot `
        -PolicyPath $EscapePolicyPath `
        -ProjectType 'website'

    Assert-SecurityBlocked `
        -Invocation $PathEscape `
        -CaseId 'authority-path-escape'

    $SecurityPassCount++

    Write-Host '[SECURITY_CASE_PASS] AUTHORITY_PATH_ESCAPE=FAIL-CLOSED'

    # --------------------------------------------------------
    # 3 - Invalid lifecycle
    # --------------------------------------------------------

    $InvalidPolicy = Read-JsonFile `
        -Path $SecurityPolicyPath

    $InvalidPolicy.status =
        'compromised-test-status'

    $InvalidPolicyPath = Join-Path `
        $SecurityFixtureRoot `
        'policy-invalid-status.json'

    Write-SecurityJson `
        -Path $InvalidPolicyPath `
        -Object $InvalidPolicy

    $InvalidLifecycle = Invoke-SecurityResolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $SecurityShadowAgency `
        -ProjectRoot $SecurityProjectRoot `
        -PolicyPath $InvalidPolicyPath `
        -ProjectType 'website'

    Assert-SecurityBlocked `
        -Invocation $InvalidLifecycle `
        -CaseId 'invalid-policy-lifecycle'

    $SecurityPassCount++

    Write-Host '[SECURITY_CASE_PASS] INVALID_POLICY_LIFECYCLE=FAIL-CLOSED'

    # --------------------------------------------------------
    # 4 - Source contract hash drift
    # --------------------------------------------------------

    $ContractPolicy = Read-JsonFile `
        -Path $SecurityPolicyPath

    $ContractPolicy.
    source_contract_hashes.
    routing_contract_sha256 = ('0' * 64)

    $ContractPolicy.
    source_contract_hashes.
    result_contract_sha256 = ('F' * 64)

    $ContractPolicyPath = Join-Path `
        $SecurityFixtureRoot `
        'policy-contract-drift.json'

    Write-SecurityJson `
        -Path $ContractPolicyPath `
        -Object $ContractPolicy

    $ContractDrift = Invoke-SecurityResolver `
        -ResolverPath $ResolverPath `
        -AgencyRoot $SecurityShadowAgency `
        -ProjectRoot $SecurityProjectRoot `
        -PolicyPath $ContractPolicyPath `
        -ProjectType 'website'

    Assert-SecurityBlocked `
        -Invocation $ContractDrift `
        -CaseId 'source-contract-hash-drift'

    $SecurityPassCount++

    Write-Host '[SECURITY_CASE_PASS] SOURCE_CONTRACT_HASH_DRIFT=FAIL-CLOSED'
}
catch {

    $SecurityFailureCount++

    throw
}
finally {

    if (
        Test-Path `
            -LiteralPath $SecurityFixtureRoot `
            -PathType Container
    ) {

        Remove-Item `
            -LiteralPath $SecurityFixtureRoot `
            -Recurse `
            -Force
    }
}

Write-Host "SECURITY_CASE_PASS_COUNT=$SecurityPassCount"
Write-Host "SECURITY_CASE_FAILURE_COUNT=$SecurityFailureCount"

if ($SecurityPassCount -ne 4) {

    throw (
        'Expected four security regression PASS results.'
    )
}

if ($SecurityFailureCount -ne 0) {

    throw 'Security regression failures detected.'
}

Write-Host '[PASS] SECURITY_REGRESSION_CASES=4/4'
Write-Host '[PASS] SECURITY_FIXTURE_ROOT_REMOVED=True'
