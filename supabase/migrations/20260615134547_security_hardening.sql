-- Security hardening: fix vulnerabilities found after pentest on 2026-06-15

-- 1. Households INSERT policy: require authentication (was open to anyone)
DROP POLICY IF EXISTS "anyone can insert a household" ON households;
CREATE POLICY "authenticated users can insert a household"
  ON households FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 2. Revoke anon execute on all public SECURITY DEFINER functions
--    Anon users have no session so these RPCs should never be callable without login
REVOKE EXECUTE ON FUNCTION public.create_household_for_user(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.my_household_id() FROM anon;
REVOKE EXECUTE ON FUNCTION public.remove_household_member(uuid, uuid) FROM anon;

-- 3. Fix mutable search_path on handle_new_user (trigger function)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'My Moneyyy User')
  );
  RETURN NEW;
END;
$$;

-- 4. Fix mutable search_path on update_goal_current_amount
CREATE OR REPLACE FUNCTION update_goal_current_amount()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE savings_goals
  SET
    current_amount = current_amount + NEW.amount,
    is_completed   = (current_amount + NEW.amount >= target_amount)
  WHERE id = NEW.goal_id;
  RETURN NEW;
END;
$$;

-- 5. Rate-limit trigger: max 30 inserts per household per minute
--    Blocks bulk-insert attacks; a real household never needs more than a few per minute
CREATE OR REPLACE FUNCTION check_transaction_rate_limit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recent_count integer;
BEGIN
  SELECT COUNT(*) INTO recent_count
  FROM transactions
  WHERE household_id = NEW.household_id
    AND created_at >= NOW() - INTERVAL '60 seconds';

  IF recent_count >= 30 THEN
    RAISE EXCEPTION 'rate_limit_exceeded'
      USING HINT = 'Too many transactions inserted in the last 60 seconds';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_transaction_rate_limit
  BEFORE INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION check_transaction_rate_limit();
