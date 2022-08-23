param(
    [Parameter(Mandatory=$false)][ValidateSet('Count', 'List')][string]$metric = 'Count',

    [Parameter(Mandatory=$false)][int]$warning = $null,
    [Parameter(Mandatory=$false)][int]$critical = $null
)


$message = "Nothing changed the status output!"
$exitcode = 3

function processCheck {
    param (
        [Parameter(Mandatory=$true)][int]$checkResult,
        [Parameter(Mandatory=$true)][int]$warningThresh,
        [Parameter(Mandatory=$true)][int]$criticalThresh,
        [Parameter(Mandatory=$false)][string]$returnMessage
    )

    [array]$returnArray
    if ((!$criticalThresh) -and (!$warningThresh) ) {

        $returnArray = @(0, "OK: $returnMessage")
    }
    elseif ($checkResult -gt $criticalThresh) {
        
        $returnArray = @(2, "CRITICAL: $returnMessage")
    }
    elseif ($checkResult -le $criticalThresh -and $checkResult -gt $warningThresh) {
        
        $returnArray = @(1, "WARNING: $returnMessage")
    }
    else {
        
        $returnArray = @(0, "OK: $returnMessage")
    }

    return $returnArray

}


$usersresult = (((quser) -replace '^>', '') -replace '\s{2,}', ',' | ConvertFrom-Csv).USERNAME
$processArray = @()

if ($metric -eq 'Count') {
    $usersresult = $usersresult.Count

    $processArray = processCheck -checkResult $usersresult `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "User $metric is $usersresult | 'User $metric'=$usersresult;$warning;$critical"
}
else {
    #Removing performance data. Not sure that a list should show perf data. 
    #Also setting warn/crit to $null.
    #Also also setting checkresult here to 0, since there's nothing really to process.
    $processArray = processCheck -checkResult 0 `
                                 -warningThresh $null `
                                 -criticalThresh $null `
                                 -returnMessage "User $metric is $usersresult"
}
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode