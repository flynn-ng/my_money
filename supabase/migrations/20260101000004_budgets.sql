CREATE TABLE budgets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  category_id  uuid NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  month        date NOT NULL,
  amount       numeric(12, 2) NOT NULL CHECK (amount > 0),
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (household_id, category_id, month)
);

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members full access"
  ON budgets FOR ALL
  USING (household_id = my_household_id())
  WITH CHECK (household_id = my_household_id());

ALTER PUBLICATION supabase_realtime ADD TABLE budgets;
