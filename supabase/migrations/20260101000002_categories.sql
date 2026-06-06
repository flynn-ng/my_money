CREATE TABLE categories (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name         text NOT NULL,
  icon         text NOT NULL,
  color        text NOT NULL,
  type         text NOT NULL CHECK (type IN ('expense', 'income', 'both')),
  is_default   boolean NOT NULL DEFAULT false,
  sort_order   int NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members full access"
  ON categories FOR ALL
  USING (household_id = my_household_id())
  WITH CHECK (household_id = my_household_id());
