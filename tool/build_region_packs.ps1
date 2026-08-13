# ASCII only, and saved with a BOM. Windows PowerShell 5.1 reads a BOM-less
# .ps1 as ANSI, where a UTF-8 em dash decodes to a byte the parser treats as a
# closing quote -- every string after it is then unbalanced and the error comes
# out as a missing brace hundreds of lines away.
#
# Builds one PMTiles pack per region in assets/regions.json (§3.1, §16.6).
#
# One voivodeship per file rather than one Poland: a player downloads the place
# they walk in, and a single national pack would be a gigabyte and a half to
# reach a city block. The catalogue's bounds are the source of truth, so adding
# a region there is all it takes to have one built.
#
# Usage:
#   .\tool\build_region_packs.ps1 -OsmPath $env:USERPROFILE\Downloads\MAPS\poland-260812.osm.pbf
#   .\tool\build_region_packs.ps1 -OsmPath ... -Only wielkopolskie,mazowieckie
#
# -OutDir and -PlanetilerJar default to the folder the extract is in, so one
# path on the command line is normally enough.
#
# Hours, not minutes. Existing outputs are skipped, so it can be stopped and
# started again.

param(
    [Parameter(Mandatory = $true)][string]$OsmPath,
    [string]$OutDir = '',
    [string]$PlanetilerJar = '',
    [string]$JavaExe = "C:\Program Files\Android\Android Studio\jbr\bin\java.exe",
    [int]$MaxZoom = 15,
    [string[]]$Only = @(),
    [string]$Heap = "6g"
)

$ErrorActionPreference = 'Stop'

# Everything lives beside the extract unless told otherwise: the jar was
# downloaded into the same folder and the packs may as well land there too.
$osmFolder = Split-Path -Parent (Resolve-Path $OsmPath)
if (-not $OutDir) { $OutDir = Join-Path $osmFolder 'packs' }
if (-not $PlanetilerJar) { $PlanetilerJar = Join-Path $osmFolder 'planetiler.jar' }

# Planetiler downloads coastlines and Natural Earth into a 'data' folder under
# the working directory. Left to itself that is wherever the script was called
# from -- which is normally the repo, where 1.4 GB of cache does not belong.
$downloadDir = Join-Path $osmFolder 'data'

foreach ($required in @($OsmPath, $PlanetilerJar, $JavaExe)) {
    if (-not (Test-Path $required)) { throw "not found: $required" }
}
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$catalogue = Get-Content "$PSScriptRoot\..\assets\regions.json" -Raw | ConvertFrom-Json

# City packs carry an absolute url and are cut by hand; this builds the regions
# the catalogue serves from one host.
# Wrapped in @() so a single match still has a .Count -- PowerShell unrolls a
# one-element pipeline into a bare object, and the progress line then reads
# "[1/]".
$regions = @($catalogue.regions | Where-Object { $Only.Count -eq 0 -or $Only -contains $_.id })

$index = 0
foreach ($region in $regions) {
    $index++
    $out = Join-Path $OutDir "$($region.id).pmtiles"

    if (Test-Path $out) {
        Write-Host "[$index/$($regions.Count)] $($region.id) -- already built, skipping"
        continue
    }

    # bounds are [west, south, east, north], which is the order planetiler wants.
    $bounds = $region.bounds -join ','

    Write-Host "[$index/$($regions.Count)] $($region.id) -- building, bounds $bounds"
    $started = Get-Date

    $arguments = @(
        "-Xmx$Heap"
        '-jar'
        $PlanetilerJar
        "--osm-path=$OsmPath"
        "--output=$out"
        "--bounds=$bounds"
        "--maxzoom=$MaxZoom"
        '--download'
        "--download-dir=$downloadDir"
        '--force'
    )
    & $JavaExe @arguments

    if ($LASTEXITCODE -ne 0) { throw "planetiler failed for $($region.id)" }

    $megabytes = [math]::Round((Get-Item $out).Length / 1MB, 1)
    $minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
    Write-Host "    done: $megabytes MB in $minutes min"
}

Write-Host ""
Write-Host "All done. Next:"
Write-Host "  dart run tool/update_region_catalogue.dart $OutDir"
Write-Host "  gh release upload maps-v1 $OutDir\*.pmtiles"
