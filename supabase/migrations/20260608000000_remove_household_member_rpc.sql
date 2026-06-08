-- Removing another member never worked: RLS blocks the caller from writing to
-- another user's row.
--   * profiles UPDATE policy   → USING (id = auth.uid())
--   * memberships DELETE policy → USING (profile_id = auth.uid())
-- Both silently no-op when an admin tries to kick someone else, so the kicked
-- member kept their membership row and could switch right back in.
--
-- Fix: a SECURITY DEFINER RPC (same pattern as create_household_for_user) that
-- bypasses RLS but authorizes the caller to be a member of the target household.
CREATE OR REPLACE FUNCTION remove_household_member(
  member_id    uuid,
  household_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Caller must belong to the household they are removing someone from.
  IF NOT EXISTS (
    SELECT 1 FROM profile_household_memberships
    WHERE profile_id = auth.uid()
      AND profile_household_memberships.household_id = remove_household_member.household_id
  ) THEN
    RAISE EXCEPTION 'Not authorized to manage this household';
  END IF;

  -- Drop the membership row.
  DELETE FROM profile_household_memberships
  WHERE profile_id = remove_household_member.member_id
    AND profile_household_memberships.household_id = remove_household_member.household_id;

  -- Clear the active-household pointer only if it points at this household.
  UPDATE profiles
  SET household_id = NULL
  WHERE id = remove_household_member.member_id
    AND profiles.household_id = remove_household_member.household_id;
END;
$$;
