# pithfinder

A crowd-sourced map for finding lemon, orange, lime, grapefruit and other citrus trees growing outdoors in London and across England. Anyone can add a tree with a photo and a pin.

**Live site:** https://robertskylar.github.io/pithfinder/

## How it works

- `index.html` is the whole app: a canvas street map, the tree list, and the add-a-tree form.
- Trees and photos are stored in [Supabase](https://supabase.com). Run `supabase-setup.sql` once in the Supabase SQL Editor to create the table, photo storage and access rules (anyone can view and add; only the owner can edit or delete, from the Supabase dashboard).
- `map/` holds the basemap: `england.json` (overview, motorways, towns), `m/*.bin` (regional tiles: A-roads, rail, coastline, parks) and `d/*.bin` (street tiles). `places.json` powers the area search.
- `tools/` has the scripts that build the map tiles from OpenStreetMap data (`extract.sh` then `build_eng.py`).

## Moderation

To hide a tree, open Supabase > Table Editor > `trees` and tick `hidden`. To delete one, delete the row (and its photo under Storage > `photos`).

## Credits and licences

- Map data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, available under the Open Database License (ODbL). The tiles in `map/` are a derived database under the same licence.
- Land polygons from [osmdata.openstreetmap.de](https://osmdata.openstreetmap.de/) (ODbL). Coastline and cities from [Natural Earth](https://www.naturalearthdata.com/) (public domain). London borough boundaries: ONS (Open Government Licence).
- Starter tree records from Home Citrus Growers, The Street Tree and Wandsworth Council, linked from each record.
- Chelsea Physic Garden photo: Northmetpit, CC BY-SA 4.0, via Wikimedia Commons.
