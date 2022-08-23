<#
.DESCRIPTION
This is a Powershell based plugin for Nagios and Nagios-Like systems. This plugin can check and report on the following:
* Whether or not a file exists (does not support directories just yet)
* Checks the size of a specified file
* Checks the number of files in a specified directory
Remember, thresholds must be breached before they are thrown.
E.g. numwarning 10 will need the number of files to be 11 or higher to throw a WARNING.
.SYNOPSIS
Nagios plugin to check whether a file exists (does not support directories just yet), the size of a specified file, or the number of files in a specified directory.
.NOTES
This plugin currently does not have a helper function to work with directories. Currently you need to have two backslashes in your directory paths. E.g. C:\\Monitoring\\MyDir\\
.PARAMETER checkPath
The path to the file or directory you wish to monitor. This is needed for all types of checks performed by the plugin.
.PARAMETER exists
The file specified should exist. If it does not, throw a CRITICAL.
.PARAMETER shouldnotexist
The file specified should not exist. If it does, throw a CRITICAL.
.PARAMETER size
Telling the plugin you wish to monitor the size of a specified file.
.PARAMETER sizewarning
Telling the plugin the size (in bytes) that the file can be before it throws a WARNING.
.PARAMETER sizecritical
Telling the plugin the size (in bytes) that the file can be before it throws a CRITICAL.
.PARAMETER number
Telling the plugin you wish to monitor the number of files in a specified directory.
.PARAMETER numwarning
Telling the plugin the number of files that can be in the directory before it throws a WARNING.
.PARAMETER numcritical
Telling the plugin the number of files that can be in the directory before it throws a CRITICAL.
.EXAMPLE
PS> .\check_windows_files.ps1 -checkPath C:\\Monitoring\\MyDir\\somelogfile.log -exists
.EXAMPLE
PS> .\check_windows_files.ps1 -checkPath C:\\Monitoring\\MyDir\\somelogfile.log -size -sizewarning 4000000000 -sizecritical 8000000000
.EXAMPLE
PS> .\check_windows_files.ps1 -checkPath C:\\Monitoring\\MyDir\\ -number -numwarning 4 -numcritical 8
#>

param (
    [Parameter(Mandatory=$true)][string]$checkPath,
    #[Parameter(Mandatory=$false)][switch]$verbose,

    [Parameter(Mandatory=$false,ParameterSetName='exists')][switch]$exists,
    [Parameter(Mandatory=$false,ParameterSetName='exists')][switch]$shouldnotexist,

    [Parameter(Mandatory=$false,ParameterSetName='size')][switch]$size,
    [Parameter(Mandatory=$false,ParameterSetName='size')][int]$sizewarning,
    [Parameter(Mandatory=$false,ParameterSetName='size')][int]$sizecritical,

    [Parameter(Mandatory=$false,ParameterSetName='number')][switch]$number,
    [Parameter(Mandatory=$false,ParameterSetName='number')][int]$numwarning,
    [Parameter(Mandatory=$false,ParameterSetName='number')][int]$numcritical

)

#Setting global error action preference
#Will probably revisit this when I add the verbose switch
$ErrorActionPreference = "SilentlyContinue"
[int]$exitCode = 2
[string]$exitMessage = "CRITICAL: something wicked happened"
[decimal]$version = 1.3

function sanitizePath {
    #TODO: Need to figure out how to sanitize a path in Powershell.
    #I want people to be able to do C:\Path\To\File, not C:\\Path\\To\\File
    param (
        [Parameter(Mandatory=$true)][string]$checkPath
    )

    $returnPath = $checkPath

    return $returnPath
}

function checkFileExists {
    param (
        [Parameter(Mandatory=$true)][string]$Path
    )

    $returnBool = $false

    if (Get-CimInstance -ClassName CIM_LogicalFile `
        -Filter "Name='$Path'" `
        -KeyOnly `
        -Namespace root\cimv2) {

        $returnBool = $true

    }

    return $returnBool
}

function checkFilesInDirectory {
    param (
        [Parameter(Mandatory=$true)][string]$Path
    )
    [int]$returnInt = 0

    $returnInt = ((Get-ChildItem $Path) | Where-Object Mode -NotLike 'd*').Count

    return $returnInt
}

function checkFileSize {
    param (
        [Parameter(Mandatory=$true)][string]$Path
    )
    $returnInt = 0

    $returnint = (Get-CimInstance -ClassName CIM_LogicalFile `
                    -Filter "Name='$Path'" `
                    -KeyOnly `
                    -Namespace root\cimv2).FileSize

    return $returnInt
}

function processCheck {
    param (
        [Parameter(Mandatory=$true)][int]$checkResult,
        [Parameter(Mandatory=$true)][int]$warningThresh,
        [Parameter(Mandatory=$true)][int]$criticalThresh,
        [Parameter(Mandatory=$false)][string]$returnMessage
    )

    [array]$returnArray

    if ($checkResult -gt $criticalThresh) {

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


## MAIN SCRIPT ##
if ($exists -eq $true) {
    #Check if a specific file or directory exists
    #exists does not get run through the processCheck function as the variables
    #don't line up as well as the other two checks.
    if (checkFileExists -Path $checkPath) {
        if ($shouldnotexist -eq $true) {
            $exitMessage = "CRITICAL: I found the file $checkPath, and it shouldn't exist!"
            $exitCode = 2
        }
        else {
            $exitMessage = "OK: I found the file $checkPath."
            $exitCode = 0
        }
    }
    else {
        if ($shouldnotexist -eq $true) {
            $exitMessage = "OK: I did not find the file $checkpath, and it shouldn't exist."
            $exitCode = 0
        }
        else {
            $exitMessage = "CRITICAL: I did not find the file, $checkPath"
            $exitCode = 2
        }
    }
}
elseif ($size -eq $true) {
    #Check the size of a specific file

    $cimObj = Get-CimInstance -ClassName CIM_LogicalFile `
            -Filter "Name='$checkPath'" `
            -KeyOnly `
            -Namespace root\cimv2

    if ($cimObj.FileType -eq "File Folder") {
        $exitMessage = "UNKNOWN: $checkPath, is a directory. Directories are not currently supported"
        $exitCode = 3
    }
    else {
        $processArray = processCheck -checkResult $cimObj.FileSize `
                     -warningThresh $sizeWarning `
                     -criticalThresh $sizeCritical `
                     -returnMessage "File size is $($cimObj.FileSize) | 'File Size'=$($cimObj.FileSize);$sizeWarning;$sizeCritical"

        #Come back to this and find out why an array with 2 elements isn't starting from 0
        $exitCode = $processArray[1]
        $exitMessage = $processArray[2]
    }

}
elseif ($number -eq $true) {
    #Check the number of files in a directory

    if ((Get-CimInstance -ClassName CIM_LogicalFile `
            -Filter "Name='$checkPath'" `
            -KeyOnly `
            -Namespace root\cimv2).FileType -ne "File Folder") {

        Write-Output "The path specified is not a directory."

    }
    else {
        $numFiles = (checkFilesInDirectory -Path $checkPath)
        $processArray = processCheck -checkResult $numFiles `
                        -warningThresh $numwarning `
                        -criticalThresh $numcritical `
                        -returnMessage "Number of files is $numFiles | 'Number of Files'=$numFiles;$numwarning;$numcritical"

        #Come back to this and find out why an array with 2 elements isn't starting from 0
        $exitCode = $processArray[1]
        $exitMessage = $processArray[2]
    }
}


Write-Output $exitMessage
exit [int]$exitCode
