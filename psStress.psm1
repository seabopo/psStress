#==================================================================================================================
#==================================================================================================================
# psSTRESS - Basic CPU and Memory Stress Module
#==================================================================================================================
#==================================================================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

Set-Variable -Scope 'Local' -Name "MODULE_ROOT" -Value $PSScriptRoot
Set-Variable -Scope 'Local' -Name "MODULE_NAME" -Value $($PSScriptRoot | Split-Path -Leaf)

@('Private','Public') | ForEach-Object {
    $export = $( $_ -eq 'Public' )
    Get-ChildItem -Path "$MODULE_ROOT\$_\*.ps1" -Recurse |
        ForEach-Object {
            . $($_.FullName)
            if ( $export ) {
                $function = $_.BaseName
                $aliases  = Get-Alias | Where-Object { $_.Source -eq $MODULE_NAME } |
                                Where-Object { $_.ReferencedCommand.Name -eq $function } |
                                    Select-Object -ExpandProperty 'name'
                Export-ModuleMember -Function ($function)
                if ( $aliases ) { Export-ModuleMember -Alias $aliases }
            }
        }
}
