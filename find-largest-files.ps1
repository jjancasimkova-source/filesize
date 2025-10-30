[CmdletBinding()]
param(
    [string[]]$Paths,
    [int]$Top = 10,
    [switch]$IncludeHidden,
    [long]$MinSizeBytes = 0,
    [string]$OutputCsv,
[switch]$HumanReadable
)

# Maintain a rolling top-N list so we don't hold every file in memory on large drives.
function Add-TopFile {
    param([pscustomobject]$File)

    $script:TopFiles.Add($File)

    $sorted = $script:TopFiles | Sort-Object -Property Length -Descending | Select-Object -First $Top

    $script:TopFiles.Clear()
    foreach ($item in $sorted) {
        $script:TopFiles.Add($item)
    }
}

if ($Top -lt 1) {
    throw "Top must be a positive integer."
}

if ($MinSizeBytes -lt 0) {
    throw "MinSizeBytes cannot be negative."
}

if (-not $Paths) {
    $Paths = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root } |
        Sort-Object -Unique
}

$TopFiles = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($path in $Paths) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "Path '$path' not found. Skipping."
        continue
    }

    Write-Verbose "Scanning $path"

    $gciParams = @{
        LiteralPath = $path
        File        = $true
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'scanErrors'
    }

    if ($IncludeHidden) {
        $gciParams['Force'] = $true
    }

    $scanErrors = @()

    try {
        Get-ChildItem @gciParams | ForEach-Object {
            if ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                return
            }

            if ($_.Length -lt $MinSizeBytes) {
                return
            }

            Add-TopFile ([pscustomobject]@{
                FullName = $_.FullName
                Length   = $_.Length
            })
        }

        if ($scanErrors.Count -gt 0) {
            Write-Warning ("Encountered {0} access errors while scanning {1}" -f $scanErrors.Count, $path)
        }
    }
    catch {
        # Keep walking other paths even if one enumeration blows up (e.g. permissions or offline drive).
        Write-Warning "Unable to enumerate '$path': $_"
    }
}

$results = $TopFiles | Sort-Object -Property Length -Descending

if ($HumanReadable) {
    $results = $results | Select-Object @{Name = 'SizeGB'; Expression = { "{0:N2}" -f ($_.Length / 1GB) } },
                                        @{Name = 'SizeMB'; Expression = { "{0:N2}" -f ($_.Length / 1MB) } },
                                        Length,
                                        FullName
}

if ($OutputCsv) {
    $results | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Verbose "Results written to $OutputCsv"
}

$results
