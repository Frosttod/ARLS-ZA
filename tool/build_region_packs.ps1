# Builds one PMTiles pack per region in assets/regions.json (§3.1, §16.6).
#
# One voivodeship per file rather than one Poland: a player downloads the place
# they walk in, and a single national pack would be a gigabyte and a half to
# reach a city block. The catalogue's bounds are the source of truth, so adding
# a region there is all it takes to have one built.
#
# Usage:
#   .\tool\build_region_packs.ps1 -OsmPath C:\Users\przem\Downloads\poland-260812.osm.pbf
#   .\tool\build_region_packs.ps1 -OsmPath ... -Only wielkopolskie,mazowieckie
#
# Hours, not minutes. Existing outputs are skipped, so it can be stopped and
# started again.

param(
    [Parameter(Mandatory = $true)][string]$OsmPath,
    [string]$OutDir = "$PSScriptRoot\..\..\..\Downloads\packs",
    [string]$PlanetilerJar = "$PSScriptRoot\..\..\..\Downloads\planetiler.jar",
    [string]$JavaExe = "C:\Program Files\Android\Android Studio\jbr\bin\java.exe",
    [int]$MaxZoom = 15,
    [string[]]$Only = @(),
    [string]$Heap = "6g"
)

$ErrorActionPreference = 'Stop'

foreach ($required in @($OsmPath, $PlanetilerJar, $JavaExe)) {
    if (-not (Test-Path $required)) { throw "not found: $required" }
}
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$catalogue = Get-Content "$PSScriptRoot\..\assets\regions.json" -Raw | ConvertFrom-Json

# City packs carry an absolute url and are cut by hand; this builds the regions
# the catalogue serves from one host.
$regions = $catalogue.regions | Where-Object { $Only.Count -eq 0 -or $Only -contains $_.id }

$index = 0
foreach ($region in $regions) {
    $index++
    $out = Join-Path $OutDir "$($region.id).pmtiles"

    if (Test-Path $out) {
        Write-Host "[$index/$($regions.Count)] $($region.id) — already built, skipping"
        continue
    }

    # bounds are [west, south, east, north], which is the order planetiler wants.
    $bounds = $region.bounds -join ','

    Write-Host "[$index/$($regions.Count)] $($region.id) — building, bounds $bounds"
    $started = Get-Date

    & $JavaExe "-Xmx$Heap" -jar $PlanetilerJar `
        "--osm-path=$OsmPath" `
        "--output=$out" `
        "--bounds=$bounds" `
        "--maxzoom=$MaxZoom" `
        --download `
        --force

    if ($LASTEXITCODE -ne 0) { throw "planetiler failed for $($region.id)" }

    $megabytes = [math]::Round((Get-Item $out).Length / 1MB, 1)
    $minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
    Write-Host "    done: $megabytes MB in $minutes min"
}

Write-Host ""
Write-Host "All done. Next:"
Write-Host "  dart run tool/update_region_catalogue.dart $OutDir"
Write-Host "  gh release upload maps-v1 $OutDir\*.pmtiles"
