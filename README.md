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

# Exclude noisy folders and extensions while including hidden/system files
pwsh -File .\find-largest-files.ps1 -Paths 'C:\','D:\Backups' `
    -ExcludePaths 'C:\Temp','D:\Backups\Cache' `
    -ExcludeExtensions '.log','tmp' `
    -IncludeHidden -HumanReadable -Verbose

# Run without changing the machine-wide execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\find-largest-files.ps1
```

### Parameters
- `Paths` - Optional array of folders or drive roots. If omitted, every filesystem drive is scanned.
- `Top` - Number of results to return. Defaults to 10.
- `IncludeHidden` - Switch that includes hidden and system files in the scan.
- `MinSizeBytes` - Ignore files smaller than this size (accepts numeric values like `1048576` or PowerShell size literals such as `200MB`). Defaults to 0.
- `OutputCsv` - Optional path to export the results as CSV in addition to printing them.
- `HumanReadable` - Adds gigabyte/megabyte columns to the output table.
- `ExcludePaths` - Paths that should be skipped (any file beneath these folders is ignored).
- `ExcludeExtensions` - File extensions to skip (accepts `.log` or bare `log` form).

## Output
The script prints a table sorted by file size. For very large disks, consider scanning one drive at a time to reduce runtime, because walking every filesystem can take a while if millions of files are present.

## Getting Started
1. Clone the repository: `git clone https://github.com/jjancasimkova-source/filesize.git`.
2. Open a PowerShell prompt and change into the repo directory.
3. If script execution is blocked, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` for the current session only.
4. Execute the script with whichever options match your scenario (see examples above).
