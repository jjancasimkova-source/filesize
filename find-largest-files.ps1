[CmdletBinding()]
param(
    [string[]]$Paths,
    [int]$Top = 10,
    [switch]$IncludeHidden
)

if (-not $Paths) {
    $Paths = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root } |
        Sort-Object -Unique
}

$fileInfo = foreach ($path in $Paths) {
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
    }

    if ($IncludeHidden) {
        $gciParams['Force'] = $true
    }

    try {
        Get-ChildItem @gciParams | Select-Object FullName, Length
    }
    catch {
        Write-Warning "Unable to enumerate '$path': $_"
    }
}

$fileInfo |
    Sort-Object -Property Length -Descending |
    Select-Object -First $Top |
    Select-Object @{Name = 'SizeGB'; Expression = { "{0:N2}" -f ($_.Length / 1GB) } },
                  @{Name = 'SizeMB'; Expression = { "{0:N2}" -f ($_.Length / 1MB) } },
                  Length,
                  FullName
