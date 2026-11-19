[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive branch selection writes options to the terminal.')]
param()

function gbranch {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Warning 'Gitが見つかりません。'; return }
    $inside = & git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') { Write-Warning 'Gitリポジトリ外です。'; return }

    $branches = @(& git for-each-ref --format='%(refname:short)' refs/heads)
    if ($LASTEXITCODE -ne 0 -or $branches.Count -eq 0) { Write-Warning 'ローカルブランチがありません。'; return }
    $current = & git branch --show-current
    Write-Host 'Git branches:'
    for ($i = 0; $i -lt $branches.Count; $i++) {
        $mark = if ($branches[$i] -eq $current) { ' (current)' } else { '' }
        Write-Host ("  {0}. {1}{2}" -f ($i + 1), $branches[$i], $mark)
    }
    $answer = (Read-Host '切り替えるブランチ番号 (Enterでキャンセル)').Trim()
    if ($answer -eq '') { return }
    $number = 0
    if (-not [int]::TryParse($answer, [ref]$number) -or $number -lt 1 -or $number -gt $branches.Count) {
        Write-Warning '有効な番号を入力してください。'
        return
    }
    $target = $branches[$number - 1]
    if ($target -eq $current) { return }
    & git switch -- $target
    if ($LASTEXITCODE -ne 0) { throw "ブランチの切り替えに失敗しました: $target" }
}
