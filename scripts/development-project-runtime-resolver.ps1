[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AgencyRoot,

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$ProjectType,

    [string]$PolicyPath,

    [ValidateSet('Existing','New')]
    [string]$ProjectLifecycle = 'Existing'
)

$ErrorActionPreference = 'Stop'

$ExpectedRoutingContractHash = '5E2856EC30DCD595414DAF689C0A606CBBD49E4013DDD102A6CED57DB7DD50C7'
$ExpectedResultContractHash = 'F08FD0BDAF311FE7EDB44251E5A72702A705E0D7DCFC26AF858F6856A8FC4872'

$ExpectedProjectTypes = @(
    'website',
    'landing-page',
    'laravel',
    'crm',
    'saas'
)

$ExpectedLaravelFamily = @(
    'laravel',
    'crm',
    'saas'
)

$ExpectedFrontendFamily = @(
    'website',
    'landing-page'
)

$ExpectedAuthorityHashes = [ordered]@{

    'config/development-runtime-bindings.json' =
        'E0BC5EF63D3B792FDB8F748193B208B44BFE3ABDAC24FCAB323E9242BEC0266D'

    'tools/registry/development-tools.json' =
        'D381EC3A153E366D91121EA873944B80A8EC618B20626D2DC18E05A15241374B'

    'config/skill-bundles.json' =
        'B47D123EF45430640736962429E2ED5721C21EC0B2D4F81C1F943D4A6E286D65'

    'agents/development/proxtel-development-orchestrator/agent.json' =
        'C22CDA4009BA104B9D6AB98E20B360D91F76DD6CFC941FB0B7C91649E7F6B711'

    'workflows/development/software-delivery/workflow.json' =
        '0ABB0019815C0ACB653B94DA7E58DF03B59C2FBE1B702E75147F166A762AEC24'

    'skills/_registry/skills-registry.json' =
        '38E1213E26A46209FA0B25072F469CA07B3564FFADDA9ADAB3DC7E3C494B9A8D'

    'scripts/skill-source-resolver.ps1' =
        '0093B1540ECB5DA2CDD6FE6CA374C74B5682A4CB9E664E7D80CC3C9908C48AE0'

    'adapters/claude/adapter.json' =
        '01219D3DE55632374E152DE0038544E9E9395DA1C952CBBE7253E8A201230A43'

    'adapters/codex/adapter.json' =
        'F1A820C848C45160CD2E92B468910B216AE05C308294714C9A96F8A087F007D0'

    'adapters/antigravity/adapter.json' =
        'C597D6CE6BE196BA8DE26A6ECB6B41AD5ED79CCB5F60F79B8C66173744EB67CF'
}

$ExpectedAuthorityPaths = [ordered]@{

    runtime_bindings =
        'config/development-runtime-bindings.json'

    skill_bundles =
        'config/skill-bundles.json'

    skill_registry =
        'skills/_registry/skills-registry.json'

    skill_source_resolver =
        'scripts/skill-source-resolver.ps1'

    tool_registry =
        'tools/registry/development-tools.json'

    workflow =
        'workflows/development/software-delivery/workflow.json'

    orchestrator =
        'agents/development/proxtel-development-orchestrator/agent.json'

    templates_root =
        'templates'

    subagents_root =
        'agents/development'

    provider_adapters_root =
        'adapters'
}

function Read-JsonFile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (
        Test-Path `
            -LiteralPath $Path `
            -PathType Leaf
    )) {

        throw "JSON authority missing [$Path]."
    }

    try {

        return (
            Get-Content `
                -LiteralPath $Path `
                -Raw `
                -Encoding UTF8 |
            ConvertFrom-Json
        )
    }
    catch {

        throw (
            "Invalid JSON authority [$Path]: " +
            [string]$_.Exception.Message
        )
    }
}

function Get-Sha256File {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (
        Get-FileHash `
            -LiteralPath $Path `
            -Algorithm SHA256
    ).Hash
}

function Assert-ExactArray {

    param(
        [Parameter(Mandatory = $true)]
        $Actual,

        [Parameter(Mandatory = $true)]
        [string[]]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $ActualArray = @($Actual)

    if ($ActualArray.Count -ne $Expected.Count) {

        throw (
            "$Label count mismatch. " +
            "expected=[$($Expected.Count)] " +
            "actual=[$($ActualArray.Count)]"
        )
    }

    for (
        $Index = 0;
        $Index -lt $Expected.Count;
        $Index++
    ) {

        if (
            [string]$ActualArray[$Index] -cne
            [string]$Expected[$Index]
        ) {

            throw (
                "$Label mismatch at index [$Index]. " +
                "expected=[$($Expected[$Index])] " +
                "actual=[$($ActualArray[$Index])]"
            )
        }
    }
}

function Assert-PolicyContract {

    param(
        [Parameter(Mandatory = $true)]
        $Policy
    )

    if (
        [string]$Policy.kind -cne
        'proxtel-development-project-runtime-policy'
    ) {
        throw 'Runtime policy kind invalid.'
    }

    $AllowedStatuses = @(
        'candidate-staged',
        'certified'
    )

    if (
        $AllowedStatuses -cnotcontains
        [string]$Policy.status
    ) {

        throw (
            "Runtime policy status invalid " +
            "[$($Policy.status)]."
        )
    }

    Assert-ExactArray `
        -Actual $Policy.supported_project_types `
        -Expected $ExpectedProjectTypes `
        -Label 'supported_project_types'

    if (
        -not [bool]$Policy.project_detection.
        explicit_project_type_precedence
    ) {
        throw 'Explicit project-type precedence must be enabled.'
    }

    if (
        [bool]$Policy.project_detection.
        semantic_subtype_guessing
    ) {
        throw 'Semantic subtype guessing must remain disabled.'
    }

    if (
        -not [bool]$Policy.project_detection.
        existing_project_read_only_discovery
    ) {
        throw 'Existing-project discovery must remain read-only.'
    }

    if (
        -not [bool]$Policy.project_detection.
        explicit_project_type_required_when_not_unique
    ) {
        throw 'Ambiguous project detection must require explicit type.'
    }

    if (
        [string]$Policy.project_detection.ambiguous_result -cne
        'blocked-ambiguous'
    ) {
        throw 'Ambiguous result contract invalid.'
    }

    if (
        [string]$Policy.project_detection.unresolved_result -cne
        'blocked-unresolved'
    ) {
        throw 'Unresolved result contract invalid.'
    }

    if (
        [string]$Policy.project_detection.unsupported_result -cne
        'blocked-unsupported'
    ) {
        throw 'Unsupported result contract invalid.'
    }

    Assert-ExactArray `
        -Actual $Policy.project_detection.laravel_family `
        -Expected $ExpectedLaravelFamily `
        -Label 'laravel_family'

    Assert-ExactArray `
        -Actual $Policy.project_detection.frontend_family `
        -Expected $ExpectedFrontendFamily `
        -Label 'frontend_family'

    if (
        [bool]$Policy.tool_relationship_model.
        primary_lane_overlap_required
    ) {
        throw 'Tool primary-lane overlap requirement must remain false.'
    }

    if (
        -not [bool]$Policy.tool_relationship_model.
        auxiliary_requires_explicit_template_listing
    ) {
        throw 'Auxiliary Tools must require explicit template listing.'
    }

    if (
        [bool]$Policy.tool_relationship_model.
        automatic_tool_expansion
    ) {
        throw 'Automatic Tool expansion must remain disabled.'
    }

    if (
        [int]$Policy.tool_relationship_model.
        expected_direct_lane_edges -ne 18
    ) {
        throw 'Expected direct Tool edge count invalid.'
    }

    if (
        [int]$Policy.tool_relationship_model.
        expected_template_authorized_auxiliary_edges -ne 2
    ) {
        throw 'Expected auxiliary Tool edge count invalid.'
    }

    Assert-ExactArray `
        -Actual $Policy.tool_relationship_model.relationship_values `
        -Expected @(
            'direct-lane',
            'template-authorized-auxiliary'
        ) `
        -Label 'tool_relationship_values'

    Assert-ExactArray `
        -Actual $Policy.tool_relationship_model.expected_auxiliary_edges `
        -Expected @(
            'website|api-tester',
            'landing-page|api-tester'
        ) `
        -Label 'expected_auxiliary_edges'

    foreach ($Property in @(
        'provider_execution',
        'model_execution',
        'tool_execution',
        'production_mutation_default',
        'database_mutation_default',
        'external_api_mutation_default',
        'automatic_dependency_installation',
        'automatic_git_add',
        'automatic_commit',
        'automatic_push',
        'automatic_deploy',
        'live_provider_availability_check'
    )) {

        if ([bool]$Policy.safety.$Property) {

            throw (
                "Unsafe policy flag [$Property] " +
                'must remain false.'
            )
        }
    }

    foreach ($Property in @(
        'local_first',
        'read_only_routing',
        'deterministic_json_result',
        'powershell_5_1_compatible'
    )) {

        if (-not [bool]$Policy.safety.$Property) {

            throw (
                "Required policy flag [$Property] " +
                'must remain true.'
            )
        }
    }

    if (
        [string]$Policy.source_contract_hashes.
        routing_contract_sha256 -cne
        $ExpectedRoutingContractHash
    ) {

        throw 'Routing contract SHA256 anchor mismatch.'
    }

    if (
        [string]$Policy.source_contract_hashes.
        result_contract_sha256 -cne
        $ExpectedResultContractHash
    ) {

        throw 'Result contract SHA256 anchor mismatch.'
    }

    $AuthorityHashProperties = @(
        $Policy.authority_hashes.PSObject.Properties
    )

    if (
        $AuthorityHashProperties.Count -ne
        $ExpectedAuthorityHashes.Count
    ) {

        throw (
            'Authority hash metadata count mismatch.'
        )
    }

    foreach (
        $Entry in
        $ExpectedAuthorityHashes.GetEnumerator()
    ) {

        $Property = `
            $Policy.authority_hashes.
            PSObject.Properties[
                [string]$Entry.Key
            ]

        if ($null -eq $Property) {

            throw (
                "Policy authority hash missing " +
                "[$($Entry.Key)]."
            )
        }

        if (
            [string]$Property.Value -cne
            [string]$Entry.Value
        ) {

            throw (
                "Policy authority hash anchor mismatch " +
                "[$($Entry.Key)]."
            )
        }
    }

    foreach (
        $Entry in
        $ExpectedAuthorityPaths.GetEnumerator()
    ) {

        $Property = `
            $Policy.authorities.
            PSObject.Properties[
                [string]$Entry.Key
            ]

        if ($null -eq $Property) {

            throw (
                "Policy authority path missing " +
                "[$($Entry.Key)]."
            )
        }

        $Actual = (
            [string]$Property.Value
        ).Replace('\','/')

        $Expected = (
            [string]$Entry.Value
        ).Replace('\','/')

        if (
            -not [string]::Equals(
                $Actual,
                $Expected,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {

            throw (
                "Authority path mismatch " +
                "[$($Entry.Key)]."
            )
        }
    }
}

function Resolve-ContainedFile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedRelative
    )

    if (
        [string]::IsNullOrWhiteSpace(
            $RelativePath
        )
    ) {
        throw 'Authority path is empty.'
    }

    if (
        [System.IO.Path]::IsPathRooted(
            $RelativePath
        )
    ) {
        throw "Rooted authority path forbidden [$RelativePath]."
    }

    $ActualNormalized = `
        $RelativePath.Replace('/','\')

    $ExpectedNormalized = `
        $ExpectedRelative.Replace('/','\')

    if (
        -not [string]::Equals(
            $ActualNormalized,
            $ExpectedNormalized,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {

        throw (
            "Authority path is not canonical. " +
            "expected=[$ExpectedRelative] " +
            "actual=[$RelativePath]"
        )
    }

    $RootFull = [System.IO.Path]::GetFullPath(
        $Root
    ).TrimEnd('\')

    $CandidateFull = [System.IO.Path]::GetFullPath(
        (
            Join-Path `
                $RootFull `
                $ActualNormalized
        )
    )

    $RootPrefix = $RootFull + '\'

    if (
        -not $CandidateFull.StartsWith(
            $RootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {

        throw (
            "Authority path escapes AgencyRoot " +
            "[$RelativePath]."
        )
    }

    if (-not (
        Test-Path `
            -LiteralPath $CandidateFull `
            -PathType Leaf
    )) {

        throw (
            "Authority file missing " +
            "[$CandidateFull]."
        )
    }

    return $CandidateFull
}

function Resolve-ContainedDirectory {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedRelative
    )

    if (
        [string]::IsNullOrWhiteSpace(
            $RelativePath
        )
    ) {
        throw 'Authority directory path is empty.'
    }

    if (
        [System.IO.Path]::IsPathRooted(
            $RelativePath
        )
    ) {
        throw "Rooted authority directory forbidden [$RelativePath]."
    }

    $ActualNormalized = `
        $RelativePath.Replace('/','\')

    $ExpectedNormalized = `
        $ExpectedRelative.Replace('/','\')

    if (
        -not [string]::Equals(
            $ActualNormalized,
            $ExpectedNormalized,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {

        throw (
            "Authority directory is not canonical. " +
            "expected=[$ExpectedRelative] " +
            "actual=[$RelativePath]"
        )
    }

    $RootFull = [System.IO.Path]::GetFullPath(
        $Root
    ).TrimEnd('\')

    $CandidateFull = [System.IO.Path]::GetFullPath(
        (
            Join-Path `
                $RootFull `
                $ActualNormalized
        )
    )

    $RootPrefix = $RootFull + '\'

    if (
        -not $CandidateFull.StartsWith(
            $RootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {

        throw (
            "Authority directory escapes AgencyRoot " +
            "[$RelativePath]."
        )
    }

    if (-not (
        Test-Path `
            -LiteralPath $CandidateFull `
            -PathType Container
    )) {

        throw (
            "Authority directory missing " +
            "[$CandidateFull]."
        )
    }

    return $CandidateFull
}

function Assert-AuthorityHash {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if (
        -not $ExpectedAuthorityHashes.
        Contains(
            $RelativePath
        )
    ) {

        throw (
            "Unknown authority hash anchor " +
            "[$RelativePath]."
        )
    }

    $ExpectedHash = `
        [string]$ExpectedAuthorityHashes[
            $RelativePath
        ]

    $ActualHash = Get-Sha256File `
        -Path $Path

    if ($ActualHash -cne $ExpectedHash) {

        throw (
            "Authority SHA256 mismatch " +
            "[$RelativePath]. " +
            "expected=[$ExpectedHash] " +
            "actual=[$ActualHash]"
        )
    }
}

function Test-JsonExactString {

    param(
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]$Needle
    )

    $Json = $Object |
        ConvertTo-Json `
            -Depth 100 `
            -Compress

    $Quoted = (
        '"' +
        $Needle.Replace('"','\"') +
        '"'
    )

    return (
        $Json.IndexOf(
            $Quoted,
            [System.StringComparison]::Ordinal
        ) -ge 0
    )
}

function Write-Resolution {

    param(
        [Parameter(Mandatory = $true)]
        $Result,

        [int]$ExitCode = 0
    )

    $Result |
        ConvertTo-Json `
            -Depth 60 `
            -Compress |
        Write-Output

    exit $ExitCode
}

function New-SafetyResult {

    return [PSCustomObject][ordered]@{

        tool_execution_allowed = $false

        provider_execution_allowed = $false

        model_execution_allowed = $false

        production_mutation_allowed = $false

        database_mutation_allowed = $false

        external_api_mutation_allowed = $false
    }
}

$ProjectFull = [System.IO.Path]::GetFullPath(
    $ProjectRoot
)

$AgencyFull = [System.IO.Path]::GetFullPath(
    $AgencyRoot
).TrimEnd('\')

$DetectionMethod = 'filesystem-evidence'
$ResolvedProjectType = $null
$Status = 'blocked-unresolved'
$DetectedCandidates = @()
$FilesystemSignals = @()

try {

    if (-not (
        Test-Path `
            -LiteralPath $AgencyFull `
            -PathType Container
    )) {

        throw 'AgencyRoot does not exist.'
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $PolicyPath
        )
    ) {

        $PolicyPath = Join-Path `
            $AgencyFull `
            'config\development-project-runtime-policy.json'
    }

    $PolicyFull = [System.IO.Path]::GetFullPath(
        $PolicyPath
    )

    $Policy = Read-JsonFile `
        -Path $PolicyFull

    # Policy trust is semantic + anchored.
    # PolicyPath may be external during staging review,
    # but its content cannot redefine canonical authorities,
    # hashes, contracts, lifecycle or execution defaults.
    Assert-PolicyContract `
        -Policy $Policy

    $SupportedTypes = @(
        $Policy.supported_project_types
    )

    $ProjectExists = Test-Path `
        -LiteralPath $ProjectFull `
        -PathType Container

    if ($ProjectExists) {

        $ArtisanPath = Join-Path `
            $ProjectFull `
            'artisan'

        $ComposerPath = Join-Path `
            $ProjectFull `
            'composer.json'

        $PackagePath = Join-Path `
            $ProjectFull `
            'package.json'

        if (
            Test-Path `
                -LiteralPath $ArtisanPath `
                -PathType Leaf
        ) {
            $FilesystemSignals += 'artisan'
        }

        if (
            Test-Path `
                -LiteralPath $ComposerPath `
                -PathType Leaf
        ) {
            $FilesystemSignals += 'composer.json'
        }

        if (
            Test-Path `
                -LiteralPath $PackagePath `
                -PathType Leaf
        ) {
            $FilesystemSignals += 'package.json'
        }

        $ViteFiles = @(
            Get-ChildItem `
                -LiteralPath $ProjectFull `
                -File `
                -Filter 'vite.config.*' `
                -ErrorAction SilentlyContinue
        )

        if ($ViteFiles.Count -gt 0) {
            $FilesystemSignals += 'vite.config.*'
        }
    }

    if (
        -not [string]::IsNullOrWhiteSpace(
            $ProjectType
        )
    ) {

        $DetectionMethod = 'explicit-project-type'

        if ($SupportedTypes -ccontains $ProjectType) {

            if ((-not $ProjectExists) -and ($ProjectLifecycle -ceq 'Existing')) {

                $Status = 'blocked-unresolved'
            }
            else {

                $ResolvedProjectType = $ProjectType
                $Status = 'resolved'
            }
        }
        else {

            $Status = 'blocked-unsupported'
        }
    }
    elseif (-not $ProjectExists) {

        $Status = 'blocked-unresolved'
    }
    elseif (
        $FilesystemSignals -ccontains
        'artisan'
    ) {

        $DetectedCandidates = @(
            $Policy.project_detection.
            laravel_family
        )

        $Status = 'blocked-ambiguous'
    }
    elseif (
        ($FilesystemSignals -ccontains 'package.json') -or
        ($FilesystemSignals -ccontains 'vite.config.*')
    ) {

        $DetectedCandidates = @(
            $Policy.project_detection.
            frontend_family
        )

        $Status = 'blocked-ambiguous'
    }
    else {

        $Status = 'blocked-unresolved'
    }

    $BaseResult = [ordered]@{

        schema_version = '1.0'

        kind =
            'proxtel-development-project-runtime-resolution'

        status = $Status

        project = [PSCustomObject][ordered]@{

            root = $ProjectFull

            project_type = $ResolvedProjectType

            detection_method = $DetectionMethod
        }

        template = $null

        lanes = @()

        skills = @()

        tools = @()

        workflow = $null

        safety = New-SafetyResult

        evidence = [PSCustomObject][ordered]@{

            project_exists = [bool]$ProjectExists

            filesystem_signals = @(
                $FilesystemSignals
            )

            detected_candidates = @(
                $DetectedCandidates
            )

            policy_path = $PolicyFull

            policy_validation = 'pass'

            authority_validation =
                'not-required-for-blocked-result'

            provider_execution = $false

            model_execution = $false

            tool_execution = $false
        }
    }

    if ($Status -ne 'resolved') {

        Write-Resolution `
            -Result (
                [PSCustomObject]$BaseResult
            ) `
            -ExitCode 0
    }

    # ========================================================
    # RESOLVED ROUTING — TRUST BOUNDARY
    # ========================================================

    $Authorities = $Policy.authorities

    $RuntimePath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.runtime_bindings) `
        -ExpectedRelative $ExpectedAuthorityPaths.runtime_bindings

    $BundlesPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.skill_bundles) `
        -ExpectedRelative $ExpectedAuthorityPaths.skill_bundles

    $SkillRegistryPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.skill_registry) `
        -ExpectedRelative $ExpectedAuthorityPaths.skill_registry

    $SkillSourceResolverPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.skill_source_resolver) `
        -ExpectedRelative $ExpectedAuthorityPaths.skill_source_resolver

    $ToolRegistryPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.tool_registry) `
        -ExpectedRelative $ExpectedAuthorityPaths.tool_registry

    $WorkflowPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.workflow) `
        -ExpectedRelative $ExpectedAuthorityPaths.workflow

    $OrchestratorPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.orchestrator) `
        -ExpectedRelative $ExpectedAuthorityPaths.orchestrator

    $TemplatesRoot = Resolve-ContainedDirectory `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.templates_root) `
        -ExpectedRelative $ExpectedAuthorityPaths.templates_root

    $SubagentsRoot = Resolve-ContainedDirectory `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.subagents_root) `
        -ExpectedRelative $ExpectedAuthorityPaths.subagents_root

    $ProviderRoot = Resolve-ContainedDirectory `
        -Root $AgencyFull `
        -RelativePath ([string]$Authorities.provider_adapters_root) `
        -ExpectedRelative $ExpectedAuthorityPaths.provider_adapters_root

    $ClaudeAdapterPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath 'adapters/claude/adapter.json' `
        -ExpectedRelative 'adapters/claude/adapter.json'

    $CodexAdapterPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath 'adapters/codex/adapter.json' `
        -ExpectedRelative 'adapters/codex/adapter.json'

    $AntigravityAdapterPath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath 'adapters/antigravity/adapter.json' `
        -ExpectedRelative 'adapters/antigravity/adapter.json'

    $AuthorityFiles = [ordered]@{

        'config/development-runtime-bindings.json' =
            $RuntimePath

        'tools/registry/development-tools.json' =
            $ToolRegistryPath

        'config/skill-bundles.json' =
            $BundlesPath

        'agents/development/proxtel-development-orchestrator/agent.json' =
            $OrchestratorPath

        'workflows/development/software-delivery/workflow.json' =
            $WorkflowPath

        'skills/_registry/skills-registry.json' =
            $SkillRegistryPath

        'scripts/skill-source-resolver.ps1' =
            $SkillSourceResolverPath

        'adapters/claude/adapter.json' =
            $ClaudeAdapterPath

        'adapters/codex/adapter.json' =
            $CodexAdapterPath

        'adapters/antigravity/adapter.json' =
            $AntigravityAdapterPath
    }

    foreach (
        $Entry in
        $AuthorityFiles.GetEnumerator()
    ) {

        Assert-AuthorityHash `
            -Path ([string]$Entry.Value) `
            -RelativePath ([string]$Entry.Key)
    }

    # Only after every canonical hash passes may the result
    # truthfully report authority_validation=pass.

    $Runtime = Read-JsonFile `
        -Path $RuntimePath

    $Bundles = Read-JsonFile `
        -Path $BundlesPath

    $SkillRegistry = Read-JsonFile `
        -Path $SkillRegistryPath

    $ToolRegistry = Read-JsonFile `
        -Path $ToolRegistryPath

    $Workflow = Read-JsonFile `
        -Path $WorkflowPath

    $Orchestrator = Read-JsonFile `
        -Path $OrchestratorPath

    $ProviderAdapters = [ordered]@{

        claude = Read-JsonFile `
            -Path $ClaudeAdapterPath

        codex = Read-JsonFile `
            -Path $CodexAdapterPath

        antigravity = Read-JsonFile `
            -Path $AntigravityAdapterPath
    }

    foreach ($ProviderId in @(
        'claude',
        'codex',
        'antigravity'
    )) {

        if (
            [string]$ProviderAdapters[$ProviderId].id -cne
            $ProviderId
        ) {

            throw (
                "Provider adapter identity mismatch " +
                "[$ProviderId]."
            )
        }
    }

    if (
        [string]$Workflow.id -cne
        'development-software-delivery'
    ) {

        throw 'Workflow identity invalid.'
    }

    if (
        [string]$Orchestrator.id -cne
        'proxtel-development-orchestrator'
    ) {

        throw 'Orchestrator identity invalid.'
    }

    if (
        [string]$Orchestrator.status -cne
        'approved'
    ) {

        throw 'Orchestrator lifecycle invalid.'
    }

    if ([bool]$ToolRegistry.execution.enabled) {
        throw 'Tool Registry execution must remain disabled.'
    }

    if ([bool]$ToolRegistry.execution.provider_execution) {
        throw 'Tool Registry provider execution must remain disabled.'
    }

    if ([bool]$ToolRegistry.execution.model_execution) {
        throw 'Tool Registry model execution must remain disabled.'
    }

    $TemplatePath = Resolve-ContainedFile `
        -Root $AgencyFull `
        -RelativePath (
            'templates/' +
            $ResolvedProjectType +
            '/template.json'
        ) `
        -ExpectedRelative (
            'templates/' +
            $ResolvedProjectType +
            '/template.json'
        )

    $Template = Read-JsonFile `
        -Path $TemplatePath

    if (
        [string]$Template.id -cne
        $ResolvedProjectType
    ) {
        throw 'Template identity mismatch.'
    }

    $Bindings = @(
        $Runtime.bindings
    )

    $RuntimeLaneIds = @(
        $Bindings |
        ForEach-Object {
            [string]$_.lane
        }
    )

    if (
        @(
            $RuntimeLaneIds |
            Select-Object -Unique
        ).Count -ne
        $Bindings.Count
    ) {

        throw 'Runtime lane IDs are not unique.'
    }

    $SubagentFiles = @(
        Get-ChildItem `
            -LiteralPath $SubagentsRoot `
            -File `
            -Filter 'subagent.json' `
            -Recurse `
            -ErrorAction Stop
    )

    $SubagentIds = @()

    foreach ($File in $SubagentFiles) {

        $SubagentFull = [System.IO.Path]::GetFullPath(
            $File.FullName
        )

        $SubagentRootPrefix = (
            [System.IO.Path]::GetFullPath(
                $SubagentsRoot
            ).TrimEnd('\') +
            '\'
        )

        if (
            -not $SubagentFull.StartsWith(
                $SubagentRootPrefix,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            throw 'Subagent path escaped canonical root.'
        }

        $Subagent = Read-JsonFile `
            -Path $SubagentFull

        if (
            -not [string]::IsNullOrWhiteSpace(
                [string]$Subagent.id
            )
        ) {

            $SubagentIds += [string]$Subagent.id
        }
    }

    $LaneResults = @()

    foreach (
        $LaneId in @(
            $Template.primary_lanes
        )
    ) {

        $Matches = @(
            $Bindings |
            Where-Object {
                [string]$_.lane -ceq
                [string]$LaneId
            }
        )

        if ($Matches.Count -ne 1) {

            throw (
                "Lane [$LaneId] must resolve " +
                'to exactly one binding.'
            )
        }

        $Binding = $Matches[0]

        $ExecutorType =
            [string]$Binding.executor_type

        $ExecutorId =
            [string]$Binding.executor_id

        if ($ExecutorType -ceq 'subagent') {

            if (
                $SubagentIds -cnotcontains
                $ExecutorId
            ) {

                throw (
                    "Subagent [$ExecutorId] " +
                    'cannot be resolved.'
                )
            }
        }
        elseif (
            $ExecutorType -ceq
            'orchestrator'
        ) {

            if (
                [string]$Orchestrator.id -cne
                $ExecutorId
            ) {

                throw (
                    "Orchestrator [$ExecutorId] " +
                    'cannot be resolved.'
                )
            }
        }
        else {

            throw (
                "Unsupported executor type " +
                "[$ExecutorType]."
            )
        }

        $ProviderIds = @(
            [string]$Binding.preferred_provider
        ) + @(
            $Binding.fallback_providers |
            ForEach-Object {
                [string]$_
            }
        )

        foreach ($ProviderId in $ProviderIds) {

            if (
                @(
                    'claude',
                    'codex',
                    'antigravity'
                ) -cnotcontains
                $ProviderId
            ) {

                throw (
                    "Unknown provider route " +
                    "[$ProviderId]."
                )
            }

            if (
                $null -eq
                $ProviderAdapters[$ProviderId]
            ) {

                throw (
                    "Provider adapter unavailable " +
                    "[$ProviderId]."
                )
            }
        }

        $LaneResults += `
            [PSCustomObject][ordered]@{

                lane = [string]$LaneId

                executor_type = $ExecutorType

                executor_id = $ExecutorId

                preferred_provider =
                    [string]$Binding.preferred_provider

                fallback_providers = @(
                    $Binding.fallback_providers
                )
            }
    }

    # ========================================================
    # SKILLS
    # ========================================================

    $BundleProperty =
        $Bundles.PSObject.Properties[
            $ResolvedProjectType
        ]

    if ($null -eq $BundleProperty) {
        throw 'Skill bundle cannot be resolved.'
    }

    $SkillResults = @()

    foreach (
        $SkillId in @(
            $BundleProperty.Value
        )
    ) {

        $SkillId = [string]$SkillId

        if (-not (
            Test-JsonExactString `
                -Object $SkillRegistry `
                -Needle $SkillId
        )) {

            throw (
                "Skill Registry cannot resolve " +
                "[$SkillId]."
            )
        }

        $SkillResults += $SkillId
    }

    # ========================================================
    # TOOLS
    # ========================================================

    $ToolResults = @()

    foreach (
        $ToolId in @(
            $Template.compatible_tools
        )
    ) {

        $ToolMatches = @(
            @($ToolRegistry.tools) |
            Where-Object {
                [string]$_.id -ceq
                [string]$ToolId
            }
        )

        if ($ToolMatches.Count -ne 1) {

            throw (
                "Tool [$ToolId] must resolve " +
                'to exactly one Registry entry.'
            )
        }

        $Tool = $ToolMatches[0]

        foreach (
            $ToolLane in @(
                $Tool.capability_lanes
            )
        ) {

            if (
                $RuntimeLaneIds -cnotcontains
                [string]$ToolLane
            ) {

                throw (
                    "Tool [$ToolId] references " +
                    "unknown lane [$ToolLane]."
                )
            }
        }

        $Overlap = @(
            @($Tool.capability_lanes) |
            Where-Object {
                @($Template.primary_lanes) -ccontains
                [string]$_
            }
        )

        $Relationship = 'direct-lane'

        if ($Overlap.Count -eq 0) {

            $Relationship =
                'template-authorized-auxiliary'
        }

        $ToolResults += `
            [PSCustomObject][ordered]@{

                id = [string]$Tool.id

                relationship = $Relationship

                capability_lanes = @(
                    $Tool.capability_lanes
                )

                registry_status =
                    [string]$Tool.status

                execution_allowed = $false
            }
    }

    $BaseResult.template =
        [PSCustomObject][ordered]@{

            id = [string]$Template.id

            status =
                [string]$Template.status

            path = (
                'templates/' +
                $ResolvedProjectType +
                '/template.json'
            )
        }

    $BaseResult.lanes = @(
        $LaneResults
    )

    $BaseResult.skills = @(
        $SkillResults
    )

    $BaseResult.tools = @(
        $ToolResults
    )

    $BaseResult.workflow =
        [PSCustomObject][ordered]@{

            id = [string]$Workflow.id

            status =
                [string]$Workflow.status

            path =
                [string]$Authorities.workflow
        }

    $BaseResult.evidence =
        [PSCustomObject][ordered]@{

            project_exists =
                [bool]$ProjectExists

            filesystem_signals = @(
                $FilesystemSignals
            )

            detected_candidates = @(
                $DetectedCandidates
            )

            policy_path = $PolicyFull

            policy_validation = 'pass'

            authority_validation = 'pass'

            authority_hash_count =
                $ExpectedAuthorityHashes.Count

            routing_contract_sha256 =
                $ExpectedRoutingContractHash

            result_contract_sha256 =
                $ExpectedResultContractHash

            provider_execution = $false

            model_execution = $false

            tool_execution = $false
        }

    Write-Resolution `
        -Result (
            [PSCustomObject]$BaseResult
        ) `
        -ExitCode 0
}
catch {

    $Failure =
        [string]$_.Exception.Message

    $FailureResult =
        [PSCustomObject][ordered]@{

            schema_version = '1.0'

            kind =
                'proxtel-development-project-runtime-resolution'

            status = 'blocked-unresolved'

            project =
                [PSCustomObject][ordered]@{

                    root = $ProjectFull

                    project_type =
                        $ResolvedProjectType

                    detection_method =
                        $DetectionMethod
                }

            template = $null

            lanes = @()

            skills = @()

            tools = @()

            workflow = $null

            safety = New-SafetyResult

            evidence =
                [PSCustomObject][ordered]@{

                    project_exists = (
                        Test-Path `
                            -LiteralPath $ProjectFull `
                            -PathType Container
                    )

                    filesystem_signals = @(
                        $FilesystemSignals
                    )

                    detected_candidates = @(
                        $DetectedCandidates
                    )

                    resolver_error =
                        $Failure

                    policy_validation =
                        'failed'

                    authority_validation =
                        'failed'

                    provider_execution =
                        $false

                    model_execution =
                        $false

                    tool_execution =
                        $false
                }
        }

    Write-Resolution `
        -Result $FailureResult `
        -ExitCode 1
}
