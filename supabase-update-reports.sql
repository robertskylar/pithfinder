-- Update 2: reports / removal requests, and a spelling fix.
-- Paste all of this into Supabase > SQL Editor > New query, then press Run. Run it once.

-- Fix a street name.
update public.trees set place = replace(place, 'Sansome', 'Sanson') where place like 'Sansome%';

-- Reports and removal requests from the "Report this tree" link and the form on the Privacy & terms page.
-- Visitors can send them; only you can read them (Table Editor > reports).
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  tree_id uuid references public.trees(id) on delete set null,
  kind text not null check (kind in ('privacy','removal','inappropriate','wrong','other')),
  message text check (char_length(message) <= 1000),
  contact text check (char_length(contact) <= 200),
  resolved boolean not null default false
);

alter table public.reports enable row level security;

create policy "Anyone can send a report" on public.reports
  for insert to anon, authenticated with check (resolved = false);

grant insert on public.reports to anon, authenticated;

-- Flood guard: at most 30 reports per hour across the whole site.
create or replace function public.limit_report_inserts() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.reports where created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Too many reports in the last hour. Please try again later.';
  end if;
  return new;
end $$;
create trigger reports_rate_limit before insert on public.reports
  for each row execute function public.limit_report_inserts();
