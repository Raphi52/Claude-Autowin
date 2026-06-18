# judge-nudge.ps1 — PostToolUse (Write|Edit): once per session, remind to run a substantial deliverable
# through `judge` before closing (the producer does not self-certify). Extracted from inline (2026-06-18).
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$fp = [string]$j.tool_input.file_path
$sid = [string]$j.session_id
$ext = ''; if ($fp) { $ext = [System.IO.Path]::GetExtension($fp).ToLower() }
if ($ext -and (@('.ps1', '.cs', '.py', '.ts', '.js', '.sql', '.md') -contains $ext)) {
    $flag = Join-Path ([System.IO.Path]::GetTempPath()) ('claude-review-nudge-' + $sid + '.flag')
    if (-not (Test-Path $flag)) {
        New-Item -ItemType File -Path $flag -Force | Out-Null
        @{ hookSpecificOutput = @{ hookEventName = 'PostToolUse'; additionalContext = 'Judge reminder (once per session): a substantial deliverable was modified. Run it through judge before closing (the producer does not self-certify), or justify the skip (disposable/trivial).' } } | ConvertTo-Json -Depth 10 -Compress
    }
}
