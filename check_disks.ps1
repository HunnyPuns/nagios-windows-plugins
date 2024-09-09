<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the usage of hard drives in operations per second. Total operations, read operations, write operations.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
A PowerShell based plugin to check the usage of hard drives.
.NOTES
This plugin currently only checks in terms of operations per second, rather than bytes per second.
.PARAMETER metric
Total, Read, or Write. Total, which is default, if you want the total number of read and write operations occurring on the disk. Read if you only want the read operations. Write if you only want the write operations.
.PARAMETER diskNum
Default is 0. This is the number of the disk on the system. Typically 0 is where the C: partition is. Especially where virtual machines are concerned.
.PARAMETER warning
The number of operations you are willing to tolerate before throwing a WARNING.
.PARAMETER critical
The number of operations you are willing to tolerate before throwing a CRITICAL.
.EXAMPLE
PS> .\check_disks.ps1 -metric Total -diskNum 0

.EXAMPLE
PS> .\check_disks.ps1 -metric Read -diskNum 0 -warning 65 -critical 100
#>
param (
    #I imagine outputType will come back if we want to add IO measurements in bytes rather than operations
    [Parameter(Mandatory=$false)][ValidateSet('Total', 'Read', 'Write')][string]$metric = 'Total',
    [Parameter(Mandatory=$false)][int]$diskNum = '0',

    [Parameter(Mandatory=$false)][int]$warning = $null,
    [Parameter(Mandatory=$false)][int]$critical = $null
)

$exitcode = 3
$exitMessage = 'Nothing changed the status output!'
$memoryresult = 0

function processCheck {
    param (
        [Parameter(Mandatory=$true)][uint64]$checkResult,
        [Parameter(Mandatory=$true)][uint64]$warningThresh,
        [Parameter(Mandatory=$true)][uint64]$criticalThresh,
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

$counterData = 0

switch ($metric) {
    #We may want to revisit the get-counter cmdlet. We have the option to get additional samples at different intervals.
    'Total' {
        $counterData = [math]::Round(((get-counter -Counter "\PhysicalDisk($diskNum*)\Disk Transfers/sec").CounterSamples).CookedValue,2)
    }

    'Read' {
        $counterData = [math]::Round(((get-counter -Counter "\PhysicalDisk($diskNum*)\Disk Reads/sec").CounterSamples).CookedValue,2)
    }

    'Write' {
        $counterData = [math]::Round(((get-counter -Counter "\PhysicalDisk($diskNum*)\Disk Writes/sec").CounterSamples).CookedValue,2)
    }

}

$processArray = processCheck -checkResult $counterData `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "$metric ops/sec is $counterData | '$metric ops/sec'=$counterData;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-output $exitMessage
exit $exitcode
