#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [psobject[]]$InputObject,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [switch]$Overwrite
)

begin {
    $ErrorActionPreference = 'Stop'

    $Rows = [System.Collections.Generic.List[object]]::new()

    $Columns = @(
        'ComputerName'
        'DNSHostName'
        'Domain'
        'OS'
        'RAM_GB'
        'LogicalCPUs'
        'LastBoot'
        'Status'
        'Error'
    )
}

process {
    foreach ($Record in $InputObject) {
        foreach ($Column in $Columns) {
            if ($Column -notin $Record.PSObject.Properties.Name) {
                throw "Input is missing inventory property: $Column"
            }
        }

        $Rows.Add(($Record | Select-Object -Property $Columns))
    }
}

end {
    if ($Rows.Count -eq 0) {
        throw 'No inventory records were supplied.'
    }

    $Rows |
        Export-Csv `
            -LiteralPath $Path `
            -NoTypeInformation `
            -Encoding UTF8 `
            -NoClobber:(-not $Overwrite)
}
