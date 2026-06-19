# model-tier.ps1 — PreToolUse (Agent|Task): force the 'sonnet' model for Explore / general-purpose
# sub-agents when no model is explicitly requested (cost economy). Pure stdin->stdout transform.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$st = $j.tool_input.subagent_type
$hasModel = $j.tool_input.PSObject.Properties.Name -contains 'model'
if (($st -eq 'Explore' -or $st -eq 'general-purpose') -and -not $hasModel) {
    $j.tool_input | Add-Member -NotePropertyName model -NotePropertyValue 'sonnet'
    @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; updatedInput = $j.tool_input } } | ConvertTo-Json -Depth 20 -Compress
}
