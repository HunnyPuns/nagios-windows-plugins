param(
    [Parameter(Mandatory=$true)][string]$volumename = 'C:\',
    [Parameter(Mandatory=$true)][ValidateSet('MB', 'GB', 'TB', 'PCT')][string]$outputType = 'PCT',
    [parameter(Mandatory=$true)][ValidateSet('Used', 'Available')][string]$metric,
    
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