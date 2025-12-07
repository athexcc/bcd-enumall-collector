# Checking administrator permissions
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You have to run as administrator" -ForegroundColor Red
    Write-Host "Rechtsklick -> Run as administrator"
    pause
    exit
}

# Banner
$banner = @'
 █████╗ ████████╗██╗  ██╗███████╗██╗  ██╗
██╔══██╗╚══██╔══╝██║  ██║██╔════╝╚██╗██╔╝
███████║   ██║   ███████║█████╗   ╚███╔╝ 
██╔══██║   ██║   ██╔══██║██╔══╝   ██╔██╗ 
██║  ██║   ██║   ██║  ██║███████╗██╔╝ ██╗
╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
'@

$colors = @("Blue", "Cyan", "Magenta", "DarkMagenta")
$lines = $banner -split "`n"
for ($i = 0; $i -lt $lines.Length; $i++) {
    $color = $colors[ [Math]::Min([int]($i / 2), $colors.Count - 1) ]
    Write-Host $lines[$i] -ForegroundColor $color
}
Write-Host "                 ⚡ A T H E X ⚡" -ForegroundColor Magenta
Start-Sleep -Milliseconds 1000

# Output file
$outputFile = "bcdedit_export_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"

Write-Host "`nEXPORTING BCD CONFIGURATION..." -ForegroundColor Cyan

try {

    $bcdOutput = bcdedit.exe /enum all 2>&1

    $rawFile = "bcdedit_raw_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    $bcdOutput | Out-File -FilePath $rawFile -Encoding UTF8

    $bootFiles = $bcdOutput | ForEach-Object {
        if ($_ -match '(\S+\.efi|\S+\.sys|BCD|bootmgr)') { $matches[1] }
    } | Select-Object -Unique

    $table = @()
    foreach ($file in $bootFiles) {
        $table += [PSCustomObject]@{
            "Boot File" = $file
            "Exists?"   = if (Test-Path $file) { "Yes" } else { "No" }
        }
    }

    $table | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

    Write-Host "`nExport completed!" -ForegroundColor Green
    Write-Host "Raw file: $((Get-Item $rawFile).FullName)" -ForegroundColor Yellow
    Write-Host "Table file: $((Get-Item $outputFile).FullName)" -ForegroundColor Yellow
}
catch {
    Write-Host "Failed to export BCD configuration: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
[Console]::ReadKey($true) | Out-Null
