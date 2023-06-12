#------------------------------------------------------------------------------------------------------------------
function Get-ThreadCounts
#------------------------------------------------------------------------------------------------------------------
{
    <#
    .DESCRIPTION
        Returns the CPU and memory thread counts to use for stress testing.

    #>
    [CmdletBinding()]
    [OutputType([String[]])]
    param (
        [Parameter()] [Int]    $CPU,
        [Parameter()] [Int]    $Memory,
        [Parameter()] [Switch] $NoCPU,
        [Parameter()] [Switch] $NoMemory
    )

    $logicalCPUs = $null
    $physicalMem = $null

    if ( $IsWindows ) {
        if ( $null -eq $(Get-Service -Name cexecsvc -ErrorAction SilentlyContinue) ) {
            $logicalCPUs = (Get-ComputerInfo).CsNumberOfLogicalProcessors
            $physicalMem = [math]::Round((Get-ComputerInfo).OsTotalVisibleMemorySize/1024)
        }
    }

    if ( $Memory -eq 0 ) {
         $Memory = if ( $NoMemory ) { 0 }
                   elseif ($physicalMem -gt 16384 ) { 2 }
                   else { 1 }
    }

    if ( $CPU -eq 0 ) {
         $CPU = if ( $NoCPU ) { 0 }
                elseif ( $logicalCPUs ) { $logicalCPUs - $memThreads }
                elseif ( $Memory -gt 2 ) { 0 }
                else { 2 - $Memory }
    }

    return $CPU,$Memory

}
