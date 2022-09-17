<#
.DESCRIPTION
A PowerShell based plugin for Nagios and Nagios-like systems. This plugin checks the network adapter statistics on Windows systems. Inbound/outbound, bits/bytes/packets, kilo/mega/giga,tera, since boot/per second. This was a pretty complex one for me, so please give me a shout if you find a bug.
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
This plugin checks the network adapter statistics on Windows systems.
.NOTES
Like I say in the description. This one was a big one for me. Please please please file an issue if you find one.
.PARAMETER netadaptername
This can be a hard one. Might be something like "Ethernet" or "Ethernet Instance" or something like that. I've added some code here so that it defaults to the first interface that's marked as Up.
.PARAMETER direciton
Inbound or Outbound. I don't have a total for this plugin. Maybe that could be an enhancement?
.PARAMETER measurement
bits, bytes, PCKTS. Do you want the data reported in bits, bytes, or packets?
.PARAMETER size
K, M, G, T. Do you want the size of the data to be reported in kilo, mega, giga, or tera?
.PARAMETER metric
Received, Sent, RecPcktError, RecDrop, SentPcktError, SentDrop. What metric do you want to report on?
Received = total received
Sent = total sent
RecPcktError = Number of error packets inbound
RecDrop = Number of inbound packets that were dropped
SentPcktError = Number of error packets outbound
SentDrop = Number of outbound packets that were dropped
.PARAMETER sinceboot
If the sinceboot flag is used, you will see the total since the system booted up.
If the sinceboot flag is not used, you will see the per second total.
.PARAMETER warning
The number you are willing to tolerate before throwing a WARNING
.PARAMETER critical
The numbery ou are willing to tolerate before throwing a CRITICAL
.EXAMPLE
PS> .\check_network_adapter.ps1 -measurement bits -size K -metric Received
.EXAMPLE
PS> .\check_network_adapter.ps1 -measurement bits -size K -metric Received -warning 60 -critical 100
#>
[CmdletBinding(DefaultParameterSetName = 'checknetadapter')]
param(
    [Parameter(Mandatory=$true)][string]$netadaptername = ((Get-NetAdapter | where -Property Status -eq 'Up' | Select-Object -First 1 ).Name),

    [Parameter(Mandatory=$true)][ValidateSet('inbound', 'outbound')][string]$direction = "outbound",

    [Parameter(Mandatory=$true, ParameterSetName='metric')][ValidateSet('bits', 'bytes', 'PCKTS')][string]$measurement = 'bits',
    [Parameter(Mandatory=$true, ParameterSetName='metric')][ValidateSet('K', 'M', 'G', 'T')][string]$size = 'M',
    [Parameter(Mandatory=$true, ParameterSetName='metric')][ValidateSet('Received', 'Sent', 'RecPcktError', 'RecDrop', 'SentPcktError', 'SentDrop')][string]$metric,

    [parameter(Mandatory=$false)][switch]$sinceboot = $null,

    [Parameter(Mandatory=$false)][int]$warning = $null,
    [Parameter(Mandatory=$false)][int]$critical = $null
)


$exitMessage = "Nothing changed the status output!"
$exitcode = 3

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

$adapterresult1 = Get-NetAdapterStatistics -Name $netadaptername
[float]$netresult = 0

if ($sinceboot -eq $True) {

    if ($direction -eq 'inbound') {
        switch ($measurement) {
            'bits' {
                $netresult = ($adapterresult1.ReceivedBytes * 8)
            }

            'bytes' {
                $netresult = $adapterresult1.ReceivedBytes
            }

            'PCKTS' {
                $netresult = $adapterresult1.ReceivedUnicastPackets
            }

        }
    }
    else {
        switch ($measurement) {
            'bits' {
                $netresult = ($adapterresult1.SentBytes * 8)
            }

            'bytes' {
                $netresult = $adapterresult1.SentBytes
            }

            'PCKTS' {
                $netresult = $adapterresult1.SentUnicastPackets
            }

        }
    }
}
else {
#Sinceboot = $False. I.e. wait 1 second, and grab the net adapter statistics again. Grab the delta.
    start-sleep 1
    $adapterresult2 = Get-NetAdapterStatistics -Name $netadaptername
    if ($direction -eq 'inbound') {
        switch ($measurement) {
            'bits' {
                $netresult = (($adapterresult2.ReceivedBytes - $adapterresult1.ReceivedBytes) * 8)
            }

            'bytes' {
                $netresult = ($adapterresult2.ReceivedBytes - $adapterresult1.ReceivedBytes)
            }

            'PCKTS' {
                $netresult = ($adapterresult2.ReceivedUnicastPackets - $adapterresult1.ReceivedUnicastPackets)
            }

        }
    }
    else {
        switch ($measurement) {
            'bits' {
                $netresult = (($adapterresult2.SentBytes - $adapterresult1.SentBytes) * 8)
            }

            'bytes' {
                $netresult = ($adapterresult2 - $adapterresult1.SentBytes)
            }

            'PCKTS' {
                $netresult = ($adapterresult2 - $adapterresult1.SentUnicastPackets)
            }

        }
    }
}

if ($measurement -ne 'PCKTS') {

    switch ($size) {
        'K' {
            $netresult = [math]::Round($netresult / 1000,2)
        }

        'M' {
            $netresult = [math]::Round($netresult / 1000 / 1000,2)
        }

        'G' {
            $netresult = [math]::Round($netresult / 1000 / 1000 / 1000,2)
        }

        'T' {
            $netresult = [math]::Round($netresult / 1000 / 1000 / 1000 / 1000,2)
        }
    }
}

$processArray = processCheck -checkResult $netresult `
                             -warningThresh $warning `
                             -criticalThresh $critical `
                             -returnMessage "$direction $size$measurement is $netresult | '$direction $size$measurement'=$netresult;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode
