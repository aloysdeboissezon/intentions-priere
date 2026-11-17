-- v45 : deux codes d'accès (administrateur et aumônier), suppression, validation, intentions « déposées », tableau de bord.
-- Les codes eux-mêmes ne sont JAMAIS écrits ici. Pour créer / remplacer le code de l'aumônier, depuis l'éditeur SQL :
--   insert into public.codes_acces(role, empreinte) values ('aumonier', extensions.crypt('<CODE>', extensions.gen_salt('bf')))
--   on conflict (role) do update set empreinte = excluded.empreinte;

alter table public.intentions add column if not exists depose_le timestamptz;
alter table public.intentions add column if not exists validee boolean not null default false;

create table if not exists public.codes_acces (
  role text primary key check (role in ('admin', 'aumonier')),
  empreinte text not null
);
alter table public.codes_acces enable row level security;
revoke all on public.codes_acces from anon, authenticated;
do $$ begin
  if to_regclass('public.benevole_code') is not null then
    insert into public.codes_acces(role, empreinte) select 'admin', empreinte from public.benevole_code on conflict (role) do nothing;
  end if;
end $$;

-- Le public ne lit plus jamais les intentions destinées à la Grotte (seul l'aumônier y a accès, via admin_lister).
alter policy "lecture publique" on public.intentions using (not masque and not lourdes);
alter policy "depot public" on public.intentions
  with check (prieres = 0 and signalements = 0 and masque = false and envoye_le is null and depose_le is null and validee = false);

create or replace function public.code_role(p_code text) returns text
language plpgsql security definer set search_path to '' as $$
declare r text;
begin
  select role into r from public.codes_acces
   where empreinte = extensions.crypt(coalesce(p_code, ''), empreinte)
   order by (role = 'aumonier') desc limit 1;
  if r is null then perform pg_sleep(1); end if;
  return r;
end $$;

create or replace function public.code_ok(p_code text) returns boolean
language sql security definer set search_path to '' as $$ select public.code_role(p_code) is not null $$;

create or replace function public.admin_role(p_code text) returns text
language plpgsql security definer set search_path to '' as $$
declare r text := public.code_role(p_code);
begin
  if r is null then raise exception 'code invalide' using errcode = '28000'; end if;
  return r;
end $$;

create or replace function public.admin_lister(p_code text) returns setof public.intentions
language plpgsql security definer set search_path to '' as $$
declare r text := public.code_role(p_code);
begin
  if r is null then raise exception 'code invalide' using errcode = '28000'; end if;
  return query select * from public.intentions i
    where not i.masque and (r = 'aumonier' or not i.lourdes)
    order by i.cree_le desc limit 3000;
end $$;

create or replace function public.admin_masquer(p_code text, p_id uuid, p_masque boolean) returns void
language plpgsql security definer set search_path to '' as $$
begin raise exception 'remplacée par admin_supprimer' using errcode = '0A000'; end $$;

create or replace function public.admin_supprimer(p_code text, p_id uuid) returns void
language plpgsql security definer set search_path to '' as $$
declare r text := public.code_role(p_code); l boolean;
begin
  if r is null then raise exception 'code invalide' using errcode = '28000'; end if;
  select lourdes into l from public.intentions where id = p_id;
  if l and r <> 'aumonier' then raise exception 'réservé à l''aumônier' using errcode = '42501'; end if;
  delete from public.journal where intention_id = p_id;
  delete from public.intentions where id = p_id;
end $$;

create or replace function public.admin_valider(p_code text, p_id uuid) returns void
language plpgsql security definer set search_path to '' as $$
declare r text := public.code_role(p_code); l boolean;
begin
  if r is null then raise exception 'code invalide' using errcode = '28000'; end if;
  select lourdes into l from public.intentions where id = p_id;
  if l and r <> 'aumonier' then raise exception 'réservé à l''aumônier' using errcode = '42501'; end if;
  update public.intentions set signalements = 0, validee = true where id = p_id;
end $$;

create or replace function public.signaler(p_id uuid, p_appareil text) returns void
language plpgsql security definer set search_path to '' as $$
begin
  if p_appareil is null or char_length(p_appareil) > 64 then return; end if;
  insert into public.journal(intention_id, appareil, type) values (p_id, p_appareil, 'signalement') on conflict do nothing;
  if found then update public.intentions set signalements = signalements + 1 where id = p_id and not validee; end if;
end $$;

create or replace function public.admin_marquer_envoyees(p_code text, p_ids uuid[]) returns integer
language plpgsql security definer set search_path to '' as $$
declare n integer;
begin
  if public.code_role(p_code) is distinct from 'aumonier' then raise exception 'code invalide' using errcode = '28000'; end if;
  update public.intentions set envoye_le = now() where id = any(p_ids) and lourdes and envoye_le is null;
  get diagnostics n = row_count; return n;
end $$;

create or replace function public.admin_marquer_deposees(p_code text, p_ids uuid[]) returns integer
language plpgsql security definer set search_path to '' as $$
declare n integer;
begin
  if public.code_role(p_code) is distinct from 'aumonier' then raise exception 'code invalide' using errcode = '28000'; end if;
  update public.intentions set depose_le = now(), envoye_le = coalesce(envoye_le, now())
   where id = any(p_ids) and lourdes and depose_le is null;
  get diagnostics n = row_count; return n;
end $$;

create or replace function public.admin_stats(p_code text) returns json
language plpgsql security definer set search_path to '' as $$
begin
  if public.code_role(p_code) is null then raise exception 'code invalide' using errcode = '28000'; end if;
  return (select json_build_object(
    'confiees', count(*),
    'prieres', coalesce(sum(prieres), 0),
    'confiants', count(distinct appareil),
    'grotte', count(*) filter (where lourdes),
    'deposees', count(*) filter (where depose_le is not null))
  from public.intentions where not masque);
end $$;

create or replace function public.compter_grotte() returns integer
language sql security definer set search_path to '' as $$
  select count(*)::integer from public.intentions where lourdes and not masque $$;

create or replace function public.admin_changer_code(p_ancien text, p_nouveau text) returns void
language plpgsql security definer set search_path to '' as $$
declare r text := public.code_role(p_ancien);
begin
  if r is null then raise exception 'code invalide' using errcode = '28000'; end if;
  if char_length(coalesce(p_nouveau, '')) < 10 then raise exception 'code trop court' using errcode = '22023'; end if;
  update public.codes_acces set empreinte = extensions.crypt(p_nouveau, extensions.gen_salt('bf')) where role = r;
end $$;
