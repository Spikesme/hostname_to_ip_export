# Interaktive Eingabe
$serverInput = Read-Host "Bitte Servernamen eingeben (kommagetrennt, z.B. server01,server02,server03)"
$dnsServer   = Read-Host "Optional: DNS-Server/DC angeben (Enter für Standard-DNS)"

# Aufbereiten
$serverNames = $serverInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }

$result = foreach ($name in $serverNames) {
    Write-Host "Bearbeite $name ..." -ForegroundColor Cyan

    try {
        if ($dnsServer) {
            $dnsResult = Resolve-DnsName -Name $name -Type A -Server $dnsServer -ErrorAction Stop
        } else {
            $dnsResult = Resolve-DnsName -Name $name -Type A -ErrorAction Stop
        }

        $ips = $dnsResult | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress

        if (-not $ips) {
            [PSCustomObject]@{
                ComputerName = $name
                IPAddress    = $null
                Status       = "Kein A-Record gefunden"
            }
        } else {
            [PSCustomObject]@{
                ComputerName = $name
                IPAddress    = ($ips -join ';')
                Status       = "OK"
            }
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $name
            IPAddress    = $null
            Status       = "Fehler: $($_.Exception.Message)"
        }
    }
}

# Ergebnis anzeigen
$result | Format-Table -AutoSize

# Optional Ergebnis speichern?
$save = Read-Host "Ergebnis als CSV speichern? (j/n)"

if ($save -eq "j") {
    $outputPath = Read-Host "Pfad zur CSV-Datei angeben (z.B. C:\Temp\ServerIPs.csv)"
    $result | Export-Csv -Path $outputPath -Encoding UTF8 -NoTypeInformation
    Write-Host "CSV gespeichert unter: $outputPath" -ForegroundColor Green
}
