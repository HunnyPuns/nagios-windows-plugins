<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the memory utilization of Windows systems. You can report the Used or Available memory in mega, giga, and terabyte, as well as percent.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
This plugin checks the memory utilization of Windows systems.
.NOTES
I plan on expanding this to include more information about the page file. I learned a lot about Windows memory management in making this plugin, and I intend to correct some out-of-date assumptions about things like the page file.
.PARAMETER outputType
MB, GB, TB, PCT. How do you want to see the output? MB = Megabytes, GB = Gigabytes, TB = Terabytes, PCT = Percent
.PARAMETER metric
Used or Available. Do you want to see how much memory you are using, or how much memory is available?
.EXAMPLE
PS> .\check_memory.ps1 -outputType MB -metric Used
.EXAMPLE
PS> .\check_memory.ps1 -outputType MB -metric Available -warning 1024 -critical 512
.EXAMPLE
PS> .\check_memory.ps1 -outputType GB -metric Used -warning 6 -critical 8
#>
param (
    [Parameter(Mandatory=$false)][ValidateSet('MB', 'GB', 'TB', 'PCT')][string]$outputType = 'MB',
    [Parameter(Mandatory=$false)][ValidateSet('Used', 'Available')][string]$metric = 'Used',

    [Parameter(Mandatory=$false)][int]$warning = $null,
    [Parameter(Mandatory=$false)][int]$critical = $null
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
    }
    else {
        if ((!$criticalThresh) -and (!$warningThresh) ) {

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

#If we're checkin' used memory, gotta change $memoryresult to reflect the used memory.
if ($metric -eq 'Used') {
    $memoryresult = $totalmem - $memoryresult
}

switch ($outputType) {
    'MB' {
            #Nothing goes here. MB is the default.
            }
    'GB' {
            $memoryresult = [math]::Round(($memoryresult / 1024), 2)
            }
    'TB' {
            $memoryresult = [math]::Round(($memoryresult / 1024 / 1024), 2)
            }
    'PCT'{
            $memoryresult = [math]::Round(($memoryresult / $totalmem) * 100, 2)
            }
}

$processArray = processCheck -checkResult $memoryresult `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "$metric memory is $memoryresult$outputType | '$metric Memory'=$memoryresult$outputType;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-output $exitMessage
exit $exitcode
