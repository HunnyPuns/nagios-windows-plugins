param (
    [Parameter(Mandatory=$false)][ValidateSet('Running', 'Stopped')][string]$expectedstate = $null,
    [Parameter(Mandatory=$false)][string]$servicename
)

$exitcode = 3
$exitMessage = 'Nothing changed the status output!'

function processCheck {
    param (
        [Parameter(Mandatory=$true)]$checkResult
    )

    [array]$returnArray

    if (!$expectedstate) {
        $returnArray = @(0, "OK: Service $($checkResult.Name) is $($checkResult.State), no expectations set")
    }
    elseif ($expectedstate -eq 'Stopped' -and $checkResult.State -eq 'Running') {
        $returnArray = @(2, "CRITICAL: Service $($checkResult.Name) is $($checkResult.State), should be 'Stopped'")
    }
    elseif ($expectedstate -eq 'Running' -and $checkResult.State -eq 'Stopped') {
        $returnArray = @(2, "CRITICAL: Service $($checkResult.Name) is $($checkResult.State), should be 'Running'")
    }
    else {
        $returnArray = @(0, "OK: Service $($checkResult.Name) is $($checkResult.State), as it should be")
    }

    return $returnArray

}


#Get a list of services
$servicedata = Get-WmiObject -Class Win32_Service | where -Property Name -eq $servicename | select -Property Name,State,ExitCode,ProcessID
$processArray = @()

if ($servicedata -eq $null) {
    $exitcode = 2
    $exitMessage = 'Could not find service named: $servicename'
}
else {
    $processArray = processCheck -checkResult $servicedata
}

$exitcode = $processArray[1]
$exitMessage = $processArray[2]

write-host $exitMessage
exit $exitcode