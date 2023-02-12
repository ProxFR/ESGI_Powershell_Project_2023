$Scriptblock = {
    $k = 0
    $pi = 0
    $limit = 10000000 + 5
    $sign = 1
    Write-Host $limit
    while ($k -lt $limit) {
        $pi = $pi + $sign * 4 / (2 * $k + 1)
        $k++
        $sign *= -1
    } 
}

$MaxThreads = 1
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$Jobs = @()

1..10 | Foreach-Object {
	$PowerShell = [powershell]::Create()
	$PowerShell.RunspacePool = $RunspacePool
	$PowerShell.AddScript($ScriptBlock).AddArgument($_)
	$Jobs += $PowerShell.BeginInvoke()
}

while ($Jobs.IsCompleted -contains $false) {
	Start-Sleep 1
}