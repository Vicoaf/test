param(
    [Parameter(Mandatory = $true)][string]$AgentJsonPath,
    [Parameter(Mandatory = $true)][string]$CapabilityMapPath,
    [Parameter(Mandatory = $true)][string]$WorkflowJsonPath,
    [Parameter(Mandatory = $true)][string]$DevelopmentStandardPath,
    [Parameter(Mandatory = $true)][string]$QaStandardPath,
    [Parameter(Mandatory = $true)][string]$GitStandardPath,
    [Parameter(Mandatory = $true)][string]$RegistryPath
)

$ErrorActionPreference = "Stop"
foreach ($Path in @($AgentJsonPath,$CapabilityMapPath,$WorkflowJsonPath,$DevelopmentStandardPath,$QaStandardPath,$GitStandardPath,$RegistryPath)) { if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw ("Missing: " + $Path) } }

$Agent = Get-Content -LiteralPath $AgentJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Map = Get-Content -LiteralPath $CapabilityMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Workflow = Get-Content -LiteralPath $WorkflowJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Dev = [System.IO.File]::ReadAllText($DevelopmentStandardPath,[System.Text.Encoding]::UTF8)
$Qa = [System.IO.File]::ReadAllText($QaStandardPath,[System.Text.Encoding]::UTF8)
$Git = [System.IO.File]::ReadAllText($GitStandardPath,[System.Text.Encoding]::UTF8)

$Passed = 0
$Failed = 0
function Check { param([string]$Name,[bool]$Condition) if ($Condition) { Write-Host ("[PASS] " + $Name); $script:Passed++ } else { Write-Host ("[FAIL] " + $Name); $script:Failed++ } }

$DevRegistry = @(@($Registry.skills) | Where-Object { [string]$_.area -ceq "development" })
$ActiveLegacy = @($DevRegistry | Where-Object { [string]$_.state -ne "baseline-existing" })

Write-Host ""
Write-Host "============================================================"
Write-Host " PROXTEL DEVELOPMENT FOUNDATION INTEGRATION TESTS"
Write-Host "============================================================"

Check "agent-workflow-reference" (@($Agent.workflows) -contains [string]$Workflow.id)
Check "agent-provider-neutral" ([bool]$Agent.provider_neutral)
Check "workflow-provider-neutral" ([bool]$Workflow.provider_neutral)
Check "map-provider-neutral" ([bool]$Map.provider_neutral)
Check "map-lanes=11" (@($Map.lanes).Count -eq 11)
Check "map-active-skills=0" (@($Map.canonical_active_development_skills).Count -eq 0)
Check "map-legacy-skills=3" (@($Map.legacy_baseline_skills).Count -eq 3)
Check "registry-development=3" ($DevRegistry.Count -eq 3)
Check "registry-development-baseline-only" ($ActiveLegacy.Count -eq 0)
Check "registry-auditor-web" (@($DevRegistry | Where-Object { [string]$_.id -ceq "auditor-web" }).Count -eq 1)
Check "registry-estratega-seo" (@($DevRegistry | Where-Object { [string]$_.id -ceq "estratega-seo" }).Count -eq 1)
Check "registry-maestro-frontend" (@($DevRegistry | Where-Object { [string]$_.id -ceq "maestro-frontend" }).Count -eq 1)
Check "development-local-first" ($Dev.Contains("local development -> validation -> staging -> production"))
Check "development-no-silent-replace" ($Dev.Contains("Do not replace working code silently."))
Check "development-no-invent" ($Dev.Contains("Do not invent missing business rules."))
Check "qa-playwright" ($Qa.Contains("Playwright"))
Check "qa-wcag22" ($Qa.Contains("WCAG 2.2"))
Check "qa-lighthouse" ($Qa.Contains("Lighthouse/Core Web Vitals"))
Check "qa-lcp-inp-cls" ($Qa.Contains("LCP, INP and CLS"))
Check "qa-independent-review" ($Qa.Contains("independent validation"))
Check "git-no-auto-commit" ($Git.Contains("Do not create commits automatically"))
Check "git-no-auto-push" ($Git.Contains("Do not push automatically"))
Check "git-diff-check" ($Git.Contains("git diff --check"))
Check "git-sensitive-artifacts" ($Git.Contains(".env files"))
Check "workflow-no-auto-deploy" ([bool]$Workflow.safety.automatic_deploy_forbidden)
Check "workflow-no-auto-live-retry" ([bool]$Workflow.safety.automatic_live_retry_forbidden)
Check "agent-no-auto-commit" ([bool]$Agent.limits.no_automatic_commit)
Check "agent-no-auto-push" ([bool]$Agent.limits.no_automatic_push)
Check "next-stage-area17" ([string]$Map.next_portfolio_stage -ceq "AREA-1.7-DEVELOPMENT-SKILL-PORTFOLIO-MODERNIZATION")

Write-Host ""
Write-Host ("INTEGRATION_ASSERTIONS=" + ($Passed + $Failed))
Write-Host ("PASSED=" + $Passed)
Write-Host ("FAILED=" + $Failed)
if ($Failed -gt 0) { throw "DEVELOPMENT FOUNDATION INTEGRATION TEST FAILURE" }
Write-Host "[PASS] ALL DEVELOPMENT FOUNDATION INTEGRATION TESTS PASSED" -ForegroundColor Green