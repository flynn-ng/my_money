-- Track all household memberships (a user can belong to multiple households)
-- profiles.household_id remains the "active" household pointer — all existing RLS unchanged
CREATE TABLE profile_household_memberships (
  profile_id   uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  joined_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, household_id)
);

ALTER TABLE profile_household_memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read their own memberships"
  ON profile_household_memberships FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "users can insert their own memberships"
  ON profile_household_memberships FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "users can leave households"
  ON profile_household_memberships FOR DELETE
  USING (profile_id = auth.uid());

-- Seed memberships from existing active household assignments
INSERT INTO profile_household_memberships (profile_id, household_id)
SELECT id, household_id FROM profiles WHERE household_id IS NOT NULL
ON CONFLICT DO NOTHING;
