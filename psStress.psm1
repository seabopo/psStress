#==================================================================================================================
#==================================================================================================================
# psSTRESS - Basic CPU and Memory Stress Module
#==================================================================================================================
#==================================================================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

Set-Variable -Scope 'Local' -Name 'MODULE_NAME' -Value $($PSScriptRoot | Split-Path -Leaf)
Set-Variable -Scope 'Local' -Name 'MODULE_ROOT' -Value $PSScriptRoot

Set-Variable -Scope 'Local' -Name 'WS_ENABLED'      -Value $false
Set-Variable -Scope 'Local' -Name 'WS_APP_LOG_PATH' -Value $( '{0}/http/app.log'     -f $PSScriptRoot )
Set-Variable -Scope 'Local' -Name 'WS_USR_LOG_PATH' -Value $( '{0}/http/usr.log'     -f $PSScriptRoot )
Set-Variable -Scope 'Local' -Name 'WS_HEADER_PATH'  -Value $( '{0}/http/header.html' -f $PSScriptRoot )
Set-Variable -Scope 'Local' -Name 'WS_FOOTER_PATH'  -Value $( '{0}/http/footer.html' -f $PSScriptRoot )
Set-Variable -Scope 'Local' -Name 'WS_START_PATH'   -Value $( '{0}/webserver.ps1'    -f $PSScriptRoot )

@('Private','Public') | ForEach-Object {
    $export = $( $_ -eq 'Public' )
    Get-ChildItem -Path "$MODULE_ROOT/$_/*.ps1" -Recurse |
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
