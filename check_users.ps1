<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the number of users logged into a Windows system. This plugin will show the number of users logged in, or a list of users logged in.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
This plugin checks the number of users logged into a Windows system.
.NOTES
Figuring out what users are connected to a Windows system is surprisingly difficult. As far as I can tell, the way that I use in this plugin is the only way to do it. And it doesn't cover SSH, FTP, or Telnet. Not that you should be using FTP or Telnet in the year of our lord, 2022.
.PARAMETER metric
Count, List. Do you want to monitor the number of users connected, or list them out? Count is the obvious choice. However, listing the users could be useful if you're using State Stalking with Nagios. This would give you rough logon/logoff times, as well as giving you an audit of who was connected to the system, and when.
.PARAMETER warning
Only works with Count. The number of users you are willing to tolerate connected to the system before you throw a WARNING.
.PARAMETER critical
Only works with Count. The number of users you are willing to tolerate connected to the system before you throw a CRITICAL.
.EXAMPLE
PS> .\check_users.ps1 -metric Count -warning 4 -critical 8
.EXAMPLE
PS> .\check_users.ps1 -metric List
#>
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
