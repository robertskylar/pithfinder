-- Citrus map setup: trees table, photo storage and access rules.
-- Paste all of this into Supabase > SQL Editor > New query, then press Run.

create table if not exists public.trees (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  species text not null check (species in ('lemon','orange','mandarin','grapefruit','pomelo','lime','other','hardy','unknown')),
  variety text check (char_length(variety) <= 80),
  place text not null check (char_length(place) between 1 and 120),
  region text check (char_length(region) <= 60),
  lat double precision not null check (lat between 49.8 and 61),
  lng double precision not null check (lng between -8.7 and 2.1),
  approx boolean not null default false,
  setting text check (setting in ('front','back','public','garden','private','pot','wall','other')),
  fruiting text check (fruiting in ('yes','flowers','no','unknown')),
  seen date,
  notes text check (char_length(notes) <= 600),
  photo_path text check (char_length(photo_path) <= 200),
  thumb_path text check (char_length(thumb_path) <= 200),
  photo_url text,
  credit text,
  credit_url text,
  source_name text,
  source text,
  seed boolean not null default false,
  hidden boolean not null default false
);

alter table public.trees enable row level security;

-- Anyone can see trees (tick "hidden" in the dashboard to hide spam).
create policy "Anyone can see visible trees" on public.trees
  for select to anon, authenticated using (hidden = false);

-- Anyone can add a tree but cannot pose as a starter record.
-- Nobody can edit or delete trees except you, from the dashboard.
create policy "Anyone can add a tree" on public.trees
  for insert to anon, authenticated
  with check (seed = false and hidden = false and photo_url is null and credit is null
              and credit_url is null and source is null and source_name is null);

-- Flood guard: at most 50 new trees per hour across the whole site.
create or replace function public.limit_tree_inserts() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.trees where created_at > now() - interval '1 hour') >= 50 then
    raise exception 'Too many new trees in the last hour. Please try again later.';
  end if;
  return new;
end $$;
create trigger trees_rate_limit before insert on public.trees
  for each row execute function public.limit_tree_inserts();

-- Photos: public to view, anyone can upload JPEGs up to 2 MB, nobody can overwrite or delete.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 2097152, array['image/jpeg'])
on conflict (id) do nothing;

create policy "Anyone can upload a tree photo" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] in ('full', 'thumb'));

-- Existing trees: 16 starter records plus the 2 you added.
insert into public.trees (species, variety, place, region, lat, lng, approx, setting, fruiting, seen, notes, photo_url, credit, credit_url, source_name, source, seed) values
  ('grapefruit', '''Queenie''', 'Chelsea Physic Garden, Chelsea', 'London', 51.48457, -0.16226, false, 'garden', 'yes', '2017-10-22', 'Planted in the ground and left uncovered in the garden''s walled microclimate. The garden bills it as the world''s most northerly fruiting outdoor grapefruit.', 'seed/chelsea-grapefruit.jpg', 'Photo: Northmetpit, CC BY-SA 4.0, via Wikimedia Commons', 'https://commons.wikimedia.org/wiki/File:Grapefruit_tree_at_Chelsea_Physic_Garden.jpg', 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('grapefruit', null, 'Queenstown Road, Battersea', 'London', 51.4688, -0.1478, true, 'front', 'yes', '2025-03-15', 'Six to eight metres tall and fruits all year. Marline Calliste Anderson brought it from Grenada as a seedling in the 1980s. Wandsworth Council protected it with Tree Preservation Order No. 510 in 2025, and a plaque now remembers her.', null, null, null, 'Lavender Hill Gazette / Wandsworth Council', 'https://lavender-hill.uk/2025/08/19/battersea_grapefruits/', true),
  ('grapefruit', null, 'Hydethorpe Road, Balham', 'London', 51.44445, -0.14266, true, 'front', 'unknown', '2019-02-01', 'Damaged in the February 2018 freeze but photographed in good condition in early 2019. Reported by Clive Lundquist.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('pomelo', 'Bangladeshi variety, probably pomelo', 'Bethnal Green', 'London', 51.52848, -0.06434, true, 'front', 'unknown', '2019-01-01', 'In the ground and uncovered in a front garden.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('unknown', null, 'Winchester Road, Edmonton N9', 'London', 51.6328, -0.0657, true, 'wall', 'yes', '2019-05-01', 'Fruiting, sheltered close to the house. About four feet tall on Street View in 2008. Reported by Ahmet Kemal.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('mandarin', 'small orange fruit', 'Burges Road, East Ham', 'London', 51.5398, 0.0625, true, 'front', 'yes', '2019-01-01', 'A tall, productive tree grown from a seedling around 2000. A second citrus grows in the same garden. Reported by Ataur Rahman.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('other', 'Satkara (Citrus macroptera)', 'Claremont Road, Forest Gate E7', 'London', 51.5488, 0.033, true, 'front', 'yes', '2019-01-01', 'Round yellow fruit and the big winged leaf stalks typical of satkara, a citrus from Bangladesh and north-east India. Reported by Ataur Rahman.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('unknown', 'large-leaved', 'Glenparke Road, Forest Gate E7', 'London', 51.5448, 0.0275, true, 'front', 'unknown', '2019-01-01', 'A large-leaved citrus of unknown type. If you know what it is, add your own sighting with a photo.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('orange', null, 'Earl''s Court Road, Kensington', 'London', 51.4948, -0.1948, true, 'front', 'yes', '2024-11-01', 'A mature tree carrying a crop of green oranges, roughly 20 to 25 years old judging by Street View from 2008, 2015 and 2023. Reported by Pascal Binon and Franck-Albert Buisson.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/londonoutdoorcitrus.html', true),
  ('lemon', null, 'Rivington Street at Garden Walk, Shoreditch', 'London', 51.5259, -0.081, true, 'public', 'unknown', '2025-01-01', 'A single lemon tree on the pedestrianised junction, one of the few citrus in a public street in London.', null, null, null, 'The Street Tree', 'https://thestreettree.substack.com/p/99-shoreditch-lemon', true),
  ('lemon', null, 'Walled garden, Osborne House, East Cowes', 'Isle of Wight', 50.7493, -1.2689, true, 'wall', 'yes', '2008-07-30', 'About three metres tall, trained flat against the south-facing wall, with plenty of green lemons in July 2008.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/isleofwight.html', true),
  ('other', 'Bergamot de Versailles', 'Walled garden, Osborne House, East Cowes', 'Isle of Wight', 50.7491, -1.2694, true, 'wall', 'no', '2008-07-30', 'Trained against the same south-facing wall as the lemon. No fruit seen in July 2008.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/isleofwight.html', true),
  ('hardy', 'Ichang papeda (Citrus ichangensis)', 'Ventnor Botanic Garden', 'Isle of Wight', 50.5888, -1.2282, true, 'garden', 'no', '2008-07-30', 'A big specimen, three to four metres tall, growing under another tree in the garden''s sheltered undercliff.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/isleofwight.html', true),
  ('hardy', 'Trifoliate orange ''Flying Dragon''', 'Ventnor Botanic Garden', 'Isle of Wight', 50.5884, -1.2275, true, 'garden', 'no', '2008-07-30', 'About a metre tall, with some yellowing leaves and die-back in 2008.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrusplaces/isleofwight.html', true),
  ('hardy', 'Swingle citrumelo (grapefruit × trifoliate orange)', 'Petworth', 'West Sussex', 50.9863, -0.6101, true, 'garden', 'yes', '2013-11-01', 'A grapefruit hybrid hardy to about -12°C. It had fruited three years running by November 2013. Location is town-level only.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrumelos/englishoutdoor.html', true),
  ('hardy', 'Citrumelo (grapefruit × trifoliate orange)', 'Nottingham', 'Nottinghamshire', 52.9548, -1.1581, true, 'wall', 'yes', '2010-11-01', 'A fine fruiting specimen against the wall of a private house. Location is city-level only.', null, null, null, 'Home Citrus Growers', 'https://www.homecitrusgrowers.co.uk/citrumelos/englishoutdoor.html', true),
  ('grapefruit', 'unsure', 'Camberwell New Road', null, 51.47533, -0.09578, false, 'front', 'yes', '2026-10-11', 'Relatively large tree in the front garden of a small church on Camberwell New Road', null, null, null, null, null, false),
  ('orange', 'blood orange', 'Sansom street', null, 51.47619, -0.0881, false, 'other', 'yes', '2026-10-09', 'in our backyard', null, null, null, null, null, false);
