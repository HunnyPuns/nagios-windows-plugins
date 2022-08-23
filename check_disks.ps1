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

write-host $exitMessage
exit $exitcode