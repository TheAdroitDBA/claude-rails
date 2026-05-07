# Auto-format files after Claude edits them

$Input = $Input | ConvertFrom-Json
$File = $Input.tool_input.file_path
if (-not $File -or -not (Test-Path $File)) { exit 0 }

switch -Regex ($File) {
    '\.swift$'              { swiftlint --fix --quiet $File 2>$null }
    '\.(ts|tsx|js|jsx)$'    { npx prettier --write $File 2>$null }
    '\.py$'                 { ruff format $File 2>$null; if ($LASTEXITCODE) { black $File 2>$null } }
    '\.rs$'                 { rustfmt $File 2>$null }
    '\.go$'                 { gofmt -w $File 2>$null }
}
