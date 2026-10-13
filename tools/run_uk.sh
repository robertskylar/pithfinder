#!/bin/bash
set -e
cd "$(dirname "$0")"
curl -sL -o uk.osm.pbf https://download.geofabrik.de/europe/united-kingdom-latest.osm.pbf
ls -la uk.osm.pbf
export P=uk.osm.pbf PFX=u_ SPAT="-spat -8.7 49.8 2.1 61.0"
./extract_map.sh 2>&1 | grep -v Warning
ogr2ogr -f GeoJSONSeq -lco COORDINATE_PRECISION=5 -spat -8.7 49.8 2.1 61.0 u_land.geojsonl /vsizip/land.zip/land-polygons-split-4326/land_polygons.shp
wc -l u_*.geojsonl
rm -rf map_uk && mkdir map_uk
ROOT=-870000,4980000,210000,6100000 PFX=u_ BASE=uk.json python3 -u build_map.py map_uk 1600000 950000 2>&1 | grep -v Warning
du -sh map_uk map_uk/m map_uk/d; ls map_uk/m | wc -l; ls map_uk/d | wc -l
