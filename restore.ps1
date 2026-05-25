$sh = New-Object -ComObject Shell.Application
$Bin = $sh.NameSpace(10)

foreach ($item in $Bin.Items()) {
    $path = $item.ExtendedProperty("System.Recycle.DeletedFrom")
    if ($path -match "2026.05.24" -or $item.Name -match "\.gd$") {
        Write-Host "Found $($item.Name) from $path"
        $verbs = $item.Verbs()
        foreach ($verb in $verbs) {
            if ($verb.Name -match "Restore|復原|還原|R&estore") {
                $verb.DoIt()
                Write-Host "Restored $($item.Name)"
                break
            }
        }
    }
}
Write-Host "Done"
