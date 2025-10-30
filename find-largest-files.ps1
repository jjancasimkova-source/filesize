<#
.SYNOPSIS
Find the largest files on one or more drives or folders.

.DESCRIPTION
Scans the provided paths (or every filesystem drive if none are supplied), keeps track of
the top N largest files, and optionally writes the results to CSV or formats sizes for
easier reading.

.PARAMETER Paths
One or more folders or drive roots to scan. Defaults to every filesystem drive.

.PARAMETER Top
How many results to keep. Must be a positive integer. Default is 10.

.PARAMETER IncludeHidden
Include hidden and system files in the scan.

.PARAMETER MinSizeBytes
Ignore files smaller than this value. Accepts numeric values or PowerShell size literals.

.PARAMETER OutputCsv
Write the results to the specified CSV file.

.PARAMETER HumanReadable
Add gigabyte and megabyte columns to the output table.

.PARAMETER ExcludePaths
Skip any files that reside under the supplied directory roots.

.PARAMETER ExcludeExtensions
Skip files whose extensions match the supplied list (ex: `.log`).
#>
[CmdletBinding()]
param(
    [string[]]$Paths,
    [int]$Top = 10,
    [switch]$IncludeHidden,
    [long]$MinSizeBytes = 0,
    [string]$OutputCsv,
    [switch]$HumanReadable,
    [string[]]$ExcludePaths,
    [string[]]$ExcludeExtensions
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

$normalizedExcludePaths = if ($ExcludePaths) {
    $ExcludePaths | ForEach-Object {
        try {
            $fullExcludePath = [System.IO.Path]::GetFullPath($_)

            if (-not $fullExcludePath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
                $fullExcludePath += [System.IO.Path]::DirectorySeparatorChar
            }

            $fullExcludePath
        }
        catch {
            Write-Warning "Exclude path '$_' is invalid and will be ignored."
            $null
        }
    } | Where-Object { $_ }
} else { @() }

$normalizedExcludeExtensions = if ($ExcludeExtensions) {
    $ExcludeExtensions | ForEach-Object {
        if ($_ -notmatch '^\.') {
            ".$_"
        }
        else {
            $_
        }
    } | ForEach-Object { $_.ToLowerInvariant() }
} else { @() }

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

    $pathFull = [System.IO.Path]::GetFullPath($path)
    if (-not $pathFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $pathFull += [System.IO.Path]::DirectorySeparatorChar
    }

    $skipPath = $false
    foreach ($excludeRoot in $normalizedExcludePaths) {
        if ($pathFull.StartsWith($excludeRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $skipPath = $true
            break
        }
    }

    if ($skipPath) {
        Write-Verbose "Skipping excluded path $path"
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

            $fullPath = $_.FullName

            foreach ($excludePath in $normalizedExcludePaths) {
                # Skip anything located under an excluded directory.
                if ($fullPath.StartsWith($excludePath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    return
                }
            }

            if ($normalizedExcludeExtensions.Count -gt 0) {
                # Skip files with extensions the caller does not care about.
                $fileExtension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
                if ($normalizedExcludeExtensions -contains $fileExtension) {
                    return
                }
            }

            Add-TopFile ([pscustomobject]@{
                FullName = $fullPath
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
