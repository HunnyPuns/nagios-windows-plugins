param (
    [Parameter(Mandatory=$true)][ValidateSet('MB', 'GB', 'TB', 'PCT')][string]$outputType,
    [Parameter(Mandatory=$true)][ValidateSet('Used', 'Available')][string]$metric,
    
    [Parameter(Mandatory=$false)][int]$warning = -1,
    [Parameter(Mandatory=$false)][int]$critical = -1
)

$exitcode = 3
$exitMessage = 'Nothing changed the status output!'
$memoryresult = 0

function processCheck {
    param (
        [Parameter(Mandatory=$true)][int]$checkResult,
        [Parameter(Mandatory=$true)][int]$warningThresh,
        [Parameter(Mandatory=$true)][int]$criticalThresh,
        [Parameter(Mandatory=$false)][string]$returnMessage
    )

    [array]$returnArray

    if ($metric -eq 'Used') {
        if (($criticalThresh -eq -1) -and ($warningThresh -eq -1) ) {

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
    }
    else {
        if (($criticalThresh -eq -1) -and ($warningThresh -eq -1) ) {

            $returnArray = @(0, "OK: $returnMessage")
        }
        elseif ($checkResult -lt $criticalThresh) {
        
            $returnArray = @(2, "CRITICAL: $returnMessage")
        }
        elseif ($checkResult -ge $criticalThresh -and $checkResult -lt $warningThresh) {
        
            $returnArray = @(1, "WARNING: $returnMessage")
        }
        else {
        
            $returnArray = @(0, "OK: $returnMessage")
        }
    }

    return $returnArray

}



$totalmem = 0
foreach ($mem in (Get-CimInstance -ClassName CIM_PhysicalMemory | select Capacity).Capacity) {
    $totalmem += $mem
}
#Total memory in MB
$totalmem = [int]($totalmem / 1024) / 1024
$memoryresult = (get-counter -counter '\Memory\Available MBytes' -computername localhost).countersamples.cookedvalue
   
    
switch ($outputType) {
    'MB' { 
            #Nothing goes here. MB is the default.
            }
    'GB' { 
            $memoryresult = $memoryresult / 1024 
            }
    'TB' { 
            $memoryresult = $memoryresult / 1024 / 1024
            }
    'PCT'{ 
            $memoryresult = [math]::Round(($memoryresult / $totalmem) * 100, 2)
            }
}

$processArray = processCheck -checkResult $memoryresult `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "$metric memory is $memoryresult | '$metric Memory'=$memoryresult$outputType;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode