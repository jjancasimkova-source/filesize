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

# Skip files smaller than 100 MB and write a CSV for later review
pwsh -File .\find-largest-files.ps1 -MinSizeBytes 100MB -OutputCsv .\largest.csv

# Include hidden/system files and show verbose progress messages
pwsh -File .\find-largest-files.ps1 -IncludeHidden -HumanReadable -Verbose
```

### Parameters
- `Paths` - Optional array of folders or drive roots. If omitted, every filesystem drive is scanned.
- `Top` - Number of results to return. Defaults to 10.
- `IncludeHidden` - Switch that includes hidden and system files in the scan.
- `MinSizeBytes` - Ignore files smaller than this size (accepts numeric values like `1048576` or PowerShell size literals such as `200MB`). Defaults to 0.
- `OutputCsv` - Optional path to export the results as CSV in addition to printing them.
- `HumanReadable` - Adds gigabyte/megabyte columns to the output table.

## Output
The script prints a table sorted by file size. For very large disks, consider scanning one drive at a time to reduce runtime, because walking every filesystem can take a while if millions of files are present.
