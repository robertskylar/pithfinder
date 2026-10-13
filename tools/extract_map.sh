#!/bin/bash
set -e
export OGR_INTERLEAVED_READING=YES
P=${P:-england.osm.pbf}
SPAT="${SPAT:--spat -6.6 49.8 2.1 56.0}"
O="-f GeoJSONSeq -lco COORDINATE_PRECISION=5"
ogr2ogr $O -simplify 0.00003 $SPAT ${PFX:-e_}roads.geojsonl $P -sql "SELECT name, highway FROM lines WHERE highway IN ('motorway','trunk','primary','secondary','tertiary','motorway_link','trunk_link','primary_link','secondary_link','residential','unclassified','living_street','pedestrian')" &
ogr2ogr $O -simplify 0.00004 $SPAT ${PFX:-e_}rail.geojsonl $P -sql "SELECT other_tags FROM lines WHERE railway = 'rail'" &
ogr2ogr $O -simplify 0.00004 $SPAT ${PFX:-e_}waterways.geojsonl $P -sql "SELECT name, waterway FROM lines WHERE waterway IN ('river','canal')" &
ogr2ogr $O $SPAT ${PFX:-e_}places.geojsonl $P -sql "SELECT name, place, other_tags FROM points WHERE place IN ('city','town','suburb','neighbourhood','quarter','village') OR other_tags LIKE '%\"railway\"=>\"station\"%'" &
wait
ogr2ogr $O -simplify 0.00003 $SPAT ${PFX:-e_}areas.geojsonl $P -sql "SELECT name, leisure, landuse, \"natural\", other_tags FROM multipolygons WHERE leisure IN ('park','garden','common','recreation_ground','golf_course','nature_reserve') OR landuse IN ('grass','cemetery','forest','meadow','recreation_ground','allotments','village_green') OR \"natural\" IN ('water','wood','heath','grassland','scrub','wetland')"
ls -la ${PFX:-e_}*.geojsonl
