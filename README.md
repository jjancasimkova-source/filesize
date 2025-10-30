# Find Largest Files Script

This repository contains a PowerShell script that enumerates one or more drives or folders and reports the largest files it finds.

## Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+
- Read access to the drives or folders you plan to scan

## Usage
```powershell
# Run from the repository root to scan all available filesystem drives
pwsh -File .\find-largest-files.ps1

# Limit the scan to specific paths and adjust how many results are returned
pwsh -File .\find-largest-files.ps1 -Paths 'C:\','D:\Backups' -Top 20

# Include hidden and system files and show verbose progress messages
pwsh -File .\find-largest-files.ps1 -IncludeHidden -Verbose
```

### Parameters
- `Paths` – Optional array of folders or drive roots. If omitted, every filesystem drive is scanned.
- `Top` – Number of results to return. Defaults to 10.
- `IncludeHidden` – Switch that includes hidden and system files in the scan.

## Output
The script prints a table with file sizes in gigabytes and megabytes alongside the full path, making it easy to identify the heaviest files on your system.
