<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks various metrics related to volumes on Windows systems. Typically this is the plugin people are looking for when they want to know the space usage of a specific drive letter in Windows. The rest of the world calls them logical volumes, but even in Windows, they are different from physical disks.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
This plugin checks various metrics related to volumes on Windows systems.
.NOTES
This plugin checks various metrics related to volumes on Windows systems. Typically this is the plugin people are looking for when they want to know the space usage of a specific drive letter in Windows.
.PARAMETER volumename
Default is C:\. Important to note that currently this does not work on NTFS mount points...yet.
.PARAMETER outputType
MB, GB, TB, PCT. How do you want the output reported? Megabytes, Gigabytes, Terabytes, Percent.
.PARAMETER metric
Used or Available. Do you want to see the space used or the space available?
.PARAMETER warning
The amount of reported space before you throw a WARNING.
.PARAMETER critical
The amount of reported space before you throw a CRITICAL.
.EXAMPLE
PS> .\check_volume.ps1 -volumename C:\ -outputType GB -metric Used
.EXAMPLE
PS> .\check_volume.ps1 -volumename D:\ -outputType GB -metric Available -warning 40 -critical 20
#>
param(
    [Parameter(Mandatory=$false)][string]$volumename = 'C:\',
    [Parameter(Mandatory=$false)][ValidateSet('MB', 'GB', 'TB', 'PCT')][string]$outputType = 'PCT',
    [parameter(Mandatory=$false)][ValidateSet('Used', 'Available')][string]$metric = 'Used',

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

if (!$volumename.EndsWith('\')) {
    $volumename = $volumename + "\"
}

$volumeresult = 0
$volume = (Get-WmiObject -Class Win32_Volume | where -Property DriveType -in -value 3,6 | where -Property Name -eq -value "$volumename")

if ($metric -eq "Used") {
    $volumeresult = $volume.Capacity - $volume.FreeSpace
    }
else {
    $volumeresult = $volume.FreeSpace
}


switch ($outputType) {
    'MB' {
            $volumeresult = [math]::Round($volumeresult / 1024 / 1024)
            }
    'GB' {
            $volumeresult = [math]::Round($volumeresult / 1024 / 1024 / 1024)
            }
    'TB' {
            $volumeresult = [math]::Round($volumeresult / 1024 / 1024 / 1024 / 1024)
            }
    'PCT'{
            $volumeresult = [math]::Round(($volume.FreeSpace / $volume.Capacity) * 100, 2)
            }
}

$processArray = processCheck -checkResult $volumeresult `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "$volumename $metric space is $volumeresult $outputType | '$volumename $metric Space'=$volumeresult$outputType;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode
