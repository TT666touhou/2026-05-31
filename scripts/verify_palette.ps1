param(
    [string]$Directory = "assets/textures"
)

Add-Type -AssemblyName System.Drawing

$files = Get-ChildItem -Path $Directory -Filter "*.png"
$allPassed = $true

foreach ($file in $files) {
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($file.FullName)
        
        $totalR = 0L
        $totalG = 0L
        $totalB = 0L
        $count = 0L
        
        for ($y = 0; $y -lt $bmp.Height; $y++) {
            for ($x = 0; $x -lt $bmp.Width; $x++) {
                $pixel = $bmp.GetPixel($x, $y)
                if ($pixel.A -gt 0) {
                    $totalR += $pixel.R
                    $totalG += $pixel.G
                    $totalB += $pixel.B
                    $count++
                }
            }
        }
        
        $bmp.Dispose()
        
        if ($count -eq 0) {
            Write-Host "[$($file.Name)] FAIL: Image is completely transparent!" -ForegroundColor Red
            $allPassed = $false
            continue
        }
        
        $avgR = $totalR / $count
        $avgG = $totalG / $count
        $avgB = $totalB / $count
        
        # Darkwood palette check:
        # Avg should be generally low (<90) and slightly warm/green-ish or neutral.
        # R: 15-90, G: 15-85, B: 15-80
        
        $pass = ($avgR -ge 10 -and $avgR -le 90) -and `
                ($avgG -ge 10 -and $avgG -le 90) -and `
                ($avgB -ge 10 -and $avgB -le 90)
                
        if ($pass) {
            Write-Host "[$($file.Name)] PASS: R:$([int]$avgR) G:$([int]$avgG) B:$([int]$avgB)" -ForegroundColor Green
        } else {
            Write-Host "[$($file.Name)] FAIL: Invalid palette! R:$([int]$avgR) G:$([int]$avgG) B:$([int]$avgB)" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[$($file.Name)] ERROR: $_" -ForegroundColor Red
        $allPassed = $false
    }
}

if (-not $allPassed) {
    Write-Host "`nValidation Failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll textures passed validation." -ForegroundColor Green
    exit 0
}
