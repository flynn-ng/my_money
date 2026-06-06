CREATE POLICY "household members can update their household"
  ON households FOR UPDATE
  USING (id = my_household_id())
  WITH CHECK (id = my_household_id());
