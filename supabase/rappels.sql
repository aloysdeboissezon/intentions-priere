-- Planification du rappel quotidien : 8 h UTC (9 h en hiver, 10 h en été, heure de Paris).
-- Remplacer <REF> par la référence du projet Supabase. Le jeton est lu dans config_push (jamais écrit ici).
select cron.schedule('rappel-quotidien', '0 8 * * *', $$
  select net.http_post(
    url := 'https://<REF>.supabase.co/functions/v1/rappels',
    headers := jsonb_build_object('x-jeton', (select jeton from public.config_push), 'Content-Type', 'application/json'),
    body := '{}'::jsonb);
$$);
