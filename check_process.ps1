<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the process information of a specified process on Windows machines. This plugin can monitor the total number of a specified process running, the total memory of all instances of said process, and the total CPU usage of said process.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
A PowerShell based plugin to the process information of a specified process on Windows machines
.NOTES
This plugin will return performance data.
.PARAMETER processname
This is the name of the process. E.g. iexplore, not iexplore.exe
.PARAMETER metric
The metric you want to alert on. I.e. Count, Memory, CPU
.PARAMETER outputType
outputType mainly affects the Memory metric. You can specify the output in KB, MB, or GB
.PARAMETER warning
The number you will tolerate before throwing a WARNING, be that for Count, Memory, or CPU
.PARAMETER critical
The number you will tolerate before throwing a CRITICAL, be that for Count, Memory, or CPU
.EXAMPLE
PS> .\check_process.ps1 -processname iexplore
.EXAMPLE
PS> .\check_process.ps1 -processname iexplore -metric Memory -outputType MB -warning 400 -critical 500 (basically throw a critical if iexplore is running, lolololol)
#>
param(
    [Parameter(Mandatory=$true)][string]$processname = $null,
    [Parameter(Mandatory=$false)][ValidateSet('Count', 'Memory', 'CPU')][string]$metric = 'Count',
    [Parameter(Mandatory=$false)][ValidateSet('KB', 'MB', 'GB')][string]$outputType = 'MB',
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

$procinfo = Get-Process -Name $processname | select -Property WS,CPU,ProcessName
#Insert error handling here if the process is not running
$message = ''
$processArray = @()

switch ($metric) {

    'Memory' {
        foreach ($mem in $procinfo.WS) { $memtotal = $memtotal + $mem }
        switch ($outputType) {
            'KB' {
                $memtotal = [math]::Round($memtotal / 1024,2)
            }

            'MB' {
                $memtotal = [math]::Round($memtotal / 1024 / 1024,2)
            }

            'GB' {
                $memtotal = [math]::Round($memtotal / 1024 /1024 /1024,2)
            }
        }

        $message = "Process $processname memory utilization is $memtotal"

        $processArray = processCheck -checkResult $memtotal `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "Process $processname memory usage is $memtotal | '$processname memory'=$memtotal;$warning;$critical"
    }

    'CPU' {
        $cputotal = [math]::Round(((get-counter "\Process($processname)\% Processor Time" -SampleInterval 1).CounterSamples).CookedValue,2)

        $processArray = processCheck -checkResult $cputotal `
                        -warningThresh $warning `
                        -criticalThresh $critical `
                        -returnMessage "Process $processname CPU usage is $cputotal | '$processname CPU usage'=$cputotal;$warning;$critical"
    }

    'Count' {
        $counttotal = @($procinfo).Count
        $message = "Process $processname Count is {0}" -f $counttotal

        $processArray = processCheck -checkResult @($procinfo).Count `
                        -warningThresh $warning `
                        -criticalThresh $critical `
                        -returnMessage "Process $processname count is $counttotal | '$processname count'=$counttotal;$warning;$critical"
    }

}

$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode
