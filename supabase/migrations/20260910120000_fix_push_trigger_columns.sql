-- Fix: the transaction push trigger read columns that do not exist, and carried
-- its webhook secret in plain text.
--
-- 1. notify_push_on_transaction() (20260616000000_push_subscriptions.sql)
--    referenced NEW.profile_id and NEW.note, but `transactions` has paid_by_id
--    and notes (20260101000003_transactions.sql). plpgsql resolves record fields
--    at run time, so every INSERT raised — and the function's own
--    `EXCEPTION WHEN OTHERS` threw the error away. The insert succeeded, no push
--    was ever sent, and nothing said why. The handler stays (a notification must
--    never fail a transaction) but now logs the reason.
--
-- 2. The webhook secret was written into that migration as a literal, so it sits
--    in git history. It is read from Supabase Vault here instead. The old value
--    must be treated as compromised and rotated:
--
--      select vault.create_secret('<new random secret>', 'push_webhook_secret');
--
--    then set the same value as WEBHOOK_SECRET in the edge function's env. Until
--    the secret exists the trigger sends nothing and logs why, rather than
--    firing an unauthenticated request.

CREATE OR REPLACE FUNCTION public.notify_push_on_transaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  webhook_secret text;
BEGIN
  SELECT decrypted_secret INTO webhook_secret
  FROM vault.decrypted_secrets
  WHERE name = 'push_webhook_secret';

  IF webhook_secret IS NULL OR webhook_secret = '' THEN
    RAISE WARNING 'push skipped for transaction %: vault secret push_webhook_secret is not set', NEW.id;
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := 'https://bvszmrfjfwjwhaxfueub.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  webhook_secret
    ),
    body    := jsonb_build_object(
      'household_id', NEW.household_id::text,
      'inserter_id',  NEW.paid_by_id::text,
      'amount',       NEW.amount,
      'type',         NEW.type,
      'note',         COALESCE(NEW.notes, '')
    )
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'push notification failed for transaction %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;
