param(
    [Parameter(Mandatory=$true)][string]$netadaptername = 'Ethernet',
    [Parameter(Mandatory=$true)][ValidateSet('Mb', 'MB', 'Gb', 'GB', 'Tb', 'TB', 'PCKT')][string]$outputType = 'Mb',
    [parameter(Mandatory=$true)][ValidateSet('Received', 'Sent', 'RecPcktError', 'SentPcktError', 'RecDrop', 'SentDrop')][string]$metric,
    [parameter(Mandatory=$false)][switch]$sinceboot,
    
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

$adapterresult = 0

switch ($metric) {
    'Received' {
        $adapterresult = (Get-NetAdapterStatistics -Name $netadaptername).ReceivedBytes
    }

    'Sent' {
    }

    'RecPcktError' {
    }

    'SentPcktError' {
    }

    'RecDrop' {
    }

    'SentDrop' {
    }

}