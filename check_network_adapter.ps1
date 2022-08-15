[CmdletBinding(DefaultParameterSetName = 'checknetadapter')]
param(
    [Parameter(Mandatory=$false)][string]$netadaptername = ((Get-NetAdapter | where -Property Status -eq 'Up' | Select-Object -First 1 ).Name),
    
    [Parameter(Mandatory=$false)][ValidateSet('inbound', 'outbound')][string]$direction = 'outbound',

    [Parameter(Mandatory=$false, ParameterSetName='metric')][ValidateSet('bits', 'bytes', 'PCKTS')][string]$metric = 'bits',
    [Parameter(Mandatory=$false, ParameterSetName='metric')][ValidateSet('K', 'M', 'G', 'T')][string]$size = 'M',
    [Parameter(Mandatory=$false, ParameterSetName='metric')][ValidateSet('Received', 'Sent', 'RecPcktError', 'RecDrop', 'SentPcktError', 'SentDrop')][string]$PCKTS,

    [parameter(Mandatory=$false)][switch]$sinceboot = $null,
    
    [Parameter(Mandatory=$false)][int]$warning = $null,
    [Parameter(Mandatory=$false)][int]$critical = $null
)


$exitMessage = "Nothing changed the status output!"
$exitcode = 3

if ( (!$bits) -and (!$bytes) -and (!$PCKTS) ) {
    $exitMessage = "You must specify one of -bits, -bytes, or -PCKTS"
    $exitcode = 4
}


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
        switch ($metric) {
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
        switch ($metric) {
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
        switch ($metric) {
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
        switch ($metric) {
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

if ($metric -ne 'PCKTS') {

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
                             -returnMessage "$direction $size$metric is $netresult | '$direction $size$metric'=$netresult;$warning;$critical"
$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode