param(
    [Parameter(Mandatory=$false)][int]$warning = -1,
    [Parameter(Mandatory=$false)][int]$critical = -1
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

    return $returnArray

}

$cpuusage = (Get-CimInstance -ClassName Win32_Processor -ComputerName localhost).LoadPercentage
$message = "CPU utilization is $cpuusage"

$processArray = processCheck -checkResult $cpuusage `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "CPU usage is $cpuusage | 'CPU Usage'=$cpuusage%;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode