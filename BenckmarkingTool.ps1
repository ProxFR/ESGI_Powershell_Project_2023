$decimals = Read-Host "Combien de décimales de Pi souhaitez-vous calculer?" #1000000
$startTime = Get-Date

$k = 0
$pi = 0
$limit = $decimals + 5
$sign = 1

while ($k -lt $limit) {
  $pi = $pi + $sign * 4 / (2 * $k + 1)
  $k++
  $sign *= -1
}

$pi = "{0:N$decimals}" -f $pi
Write-Host $pi

$elapsedTime = (Get-Date) - $startTime
Write-Host "Elapsed time: $($elapsedTime.TotalSeconds) seconds"
