function Write-Info
{
    <#
    .SYNOPSIS
        Writes a formatted status message to the console.

    .DESCRIPTION
        Writes a formatted status message to the console.

    .PARAMETER Message
        REQUIRED. String. Alias: -m. The message to be written to the console or log.

    .PARAMETER Type
        OPTIONAL. String. Alias: -t. The type of message to write, which determines the color.
                  Valid types:
                    - Header   { Color = Magenta }
                    - Process  { Color = Cyan    }
                    - Info     { Color = Gray    }
                    - Success  { Color = Green   }
                    - Warning  { Color = Yellow  }
                    - Error    { Color = Red     }

    .PARAMETER Header
        OPTIONAL. Switch. Alias: -h. Switch alternative for the Header Type paramater.

    .PARAMETER Process
        OPTIONAL. Switch. Alias: -p. Switch alternative for the Process Type paramater.

    .PARAMETER Info
        OPTIONAL. Switch. Alias: -i. Switch alternative for the Info Type paramater.

    .PARAMETER Success
        OPTIONAL. Switch. Alias: -s. Switch alternative for the Type paramater. Writes a green colored message.

    .PARAMETER Warning
        OPTIONAL. Switch. Alias: -w. Switch alternative for the Warning Type paramater.

    .PARAMETER Err
        OPTIONAL. Switch. Alias: -e. Switch alternative for the Error Type paramater.

    .PARAMETER Banner
        OPTIONAL. Switch. Alias: -b. Writes a line of dashes above and below the message to make it more visible.

    .PARAMETER DoubleBanner
        OPTIONAL. Switch. Alias: -bb. Writes two lines of dashes above and below the message to make it more visible.

    .PARAMETER TimeStamps
        OPTIONAL. Switch. Alias: -ts. Writing the timestamp to the message.

    .PARAMETER Labels
        OPTIONAL. Switch. Alias: -l. Skips appending the SUCCESS, WARNING, ERROR, or FAILURE label to the message.

    .PARAMETER DoubleSpace
        OPTIONAL. Switch. Alias: -ds. Adds a blank line after the logged item.

    .PARAMETER PreSpace
        OPTIONAL. Switch. Alias: -ps. Adds a blank line before the logged item.

    .PARAMETER NoLog
        OPTIONAL. Switch. Alias: -nl. Writes to the console only, and skips the log file.

    .PARAMETER PSCustomObject
        OPTIONAL. Switch. Alias: -co. A PSCustomObject which will have all properties written.

    .EXAMPLE
        Write-Status -Type 'Information' -Message 'Testing ...'

    .EXAMPLE
        Write-Status -I -M 'Testing ...'
    #>

    [CmdletBinding(DefaultParameterSetName = "isInformation")]
    param (
        [parameter(ValueFromPipeline)]
        [AllowEmptyString()][AllowNull()]
        [Alias('m')]  [string]         $Message,

        [Parameter(ParameterSetName = "byTypeName")]
        [ValidateSet('Header','Process','Info','Success','Warning','Error')]
        [Alias('t')]  [string]         $Type,

        [Parameter(ParameterSetName = "isHeader")]
        [Alias('h')]  [switch]         $Header,

        [Parameter(ParameterSetName = "isProcess")]
        [Alias('p')]  [switch]         $Process,

        [Parameter(ParameterSetName = "isInformation")]
        [Alias('i')]  [switch]         $Information,

        [Parameter(ParameterSetName = "isSuccess")]
        [Alias('s')]  [switch]         $Success,

        [Parameter(ParameterSetName = "isWarning")]
        [Alias('w')]  [switch]         $Warning,

        [Parameter(ParameterSetName = "isError")]
        [Alias('e')]  [switch]         $Err,

        [Alias('l')]  [switch]         $Labels,
        [Alias('b')]  [switch]         $Banner,
        [Alias('bb')] [switch]         $DoubleBanner,
        [Alias('ts')] [switch]         $TimeStamps,
        [Alias('ds')] [switch]         $DoubleSpace,
        [Alias('ps')] [switch]         $PreSpace,
        [Alias('nl')] [switch]         $NoLog,
        [Alias('co')] [PSCustomObject] $PSCustomObject
    )

    process
    {
        if ( [String]::IsNullOrEmpty($Type) )
        {
            $Type = if     ( $Header      )  { 'Header'  }
                    elseif ( $Process     )  { 'Process' }
                    elseif ( $Success     )  { 'Success' }
                    elseif ( $Warning     )  { 'Warning' }
                    elseif ( $Err         )  { 'Error'   }
                    else                     { 'Info'    }
        }

        switch ( $Type )
        {
            "Process" { $MessageColor = "Cyan"    }
            "Header"  { $MessageColor = "Magenta" }
            "Info"    { $MessageColor = "Gray"    }
            "Success" { $MessageColor = "Green"   }
            "Warning" { $MessageColor = "Yellow"  }
            "Error"   { $MessageColor = "Red"     }
            default   { $MessageColor = "Gray"    }
        }

        if ( $Labels )
        {
            switch ( $Type )
            {
                'Success'  { $Message = $( "SUCCESS: {0}" -f $Message ) }
                'Warning'  { $Message = $( "WARNING: {0}" -f $Message ) }
                'Error'    { $Message = $( "ERROR: {0}"   -f $Message ) }
            }
        }

        if ( $TimeStamps ) {
            $Message = $( "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  {0}" -f $Message )
        }

        if ( $Banner) {
            $Message = $( "$('-' * 80)`r`n{0}`r`n$('-' * 80)" -f $Message )
        }

        if ( $DoubleBanner ) {
            $Message = $( "$('-' * 80)`r`n$('-' * 80)`r`n{0}`r`n$('-' * 80)`r`n$('-' * 80)" -f $Message )
        }

        if ( $PreSpace ) { Write-Host '' }

        Write-Host "$Message" -ForegroundColor $MessageColor

        if ( $PSCustomObject ) { $PSCustomObject.GetEnumerator() | Sort-Object Name | Out-String }

        if ( $DoubleSpace ) { Write-Host '' }

        if ( -not $NoLog ) {

            if ( $PreSpace ) { '' | Out-File $WS_APP_LOG_PATH -Append }

            $Message | Out-File $WS_APP_LOG_PATH -Append

            if ( $PSCustomObject ) { $PSCustomObject.GetEnumerator() | Sort-Object Name | Out-File $WS_APP_LOG_PATH -Append }

            if ( $DoubleSpace ) { '' | Out-File $WS_APP_LOG_PATH -Append }

        }
    }
}
