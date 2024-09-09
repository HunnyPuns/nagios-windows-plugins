<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the CPU utilization on Windows machines. This plugin gives you the average CPU usage across all CPUs and all cores.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
A PowerShell based plugin to check CPU utilization on Windows machines
.NOTES
This plugin does not have the option to show individual utilization per CPU or per core.
This plugin will return performance data.
.PARAMETER warning
The CPU utilization you will tolerate before throwing a WARNING
.PARAMETER critical
The CPU utilization you will tolerate before throwing a CRITICAL
.EXAMPLE
PS> .\check_cpu.ps1
.EXAMPLE
PS> .\check_cpu.ps1 -warning 80 -critical 90
#>
param(
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

$cpus = (Get-CimInstance -ClassName Win32_Processor -ComputerName localhost).LoadPercentage
$cpuusage = 0


foreach ($cpu in $cpus) {
    $cpuusage += $cpu
}

$message = "CPU utilization is $cpuusage"

$processArray = processCheck -checkResult $cpuusage `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "CPU usage is $cpuusage | 'CPU Usage'=$cpuusage%;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-output $exitMessage
exit $exitcode
