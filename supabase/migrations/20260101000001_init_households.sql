-- Households table
CREATE TABLE households (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL DEFAULT 'Our Home',
  invite_code text UNIQUE NOT NULL DEFAULT substring(gen_random_uuid()::text, 1, 8),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Profiles (one per auth user)
CREATE TABLE profiles (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  household_id uuid REFERENCES households(id),
  display_name text NOT NULL DEFAULT 'CozyBee User',
  avatar_emoji text NOT NULL DEFAULT '🐝',
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'My Moneyyy User')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Helper: returns the household_id of the current user.
-- SECURITY DEFINER bypasses RLS on profiles, preventing circular recursion:
-- profiles RLS → my_household_id() → profiles SELECT → RLS → infinite loop.
CREATE OR REPLACE FUNCTION my_household_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT household_id FROM profiles WHERE id = auth.uid()
$$;

-- RLS: profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users in same household can view profiles"
  ON profiles FOR SELECT
  USING (household_id = my_household_id() OR id = auth.uid());
CREATE POLICY "users can update their own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid());
CREATE POLICY "users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- RLS: households (read only via membership)
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members can read their household"
  ON households FOR SELECT
  USING (id = my_household_id());
CREATE POLICY "anyone can insert a household"
  ON households FOR INSERT
  WITH CHECK (true);
