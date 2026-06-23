-- Push subscriptions for PWA Web Push notifications

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE TABLE public.push_subscriptions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  endpoint    TEXT NOT NULL,
  p256dh      TEXT NOT NULL,
  auth        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (profile_id, endpoint)
);

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "push_subscriptions_own"
  ON public.push_subscriptions
  FOR ALL
  TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

REVOKE ALL ON public.push_subscriptions FROM anon;

-- Trigger function: fire-and-forget webhook to edge function on transaction insert
CREATE OR REPLACE FUNCTION public.notify_push_on_transaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url     := 'https://bvszmrfjfwjwhaxfueub.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  '41f5a31c38164f8724e66f8cfe821c0f6f9801531946d065ad8f7a1101e0b6c0'
    ),
    body    := jsonb_build_object(
      'household_id', NEW.household_id::text,
      'inserter_id',  NEW.profile_id::text,
      'amount',       NEW.amount,
      'type',         NEW.type,
      'note',         COALESCE(NEW.note, '')
    )
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW; -- never fail the transaction due to push
END;
$$;

CREATE TRIGGER on_transaction_insert_push
  AFTER INSERT ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.notify_push_on_transaction();
