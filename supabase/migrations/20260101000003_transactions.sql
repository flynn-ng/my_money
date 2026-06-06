CREATE TABLE transactions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  paid_by_id   uuid NOT NULL REFERENCES profiles(id),
  category_id  uuid NOT NULL REFERENCES categories(id),
  type         text NOT NULL CHECK (type IN ('expense', 'income')),
  amount       numeric(12, 2) NOT NULL CHECK (amount > 0),
  date         date NOT NULL,
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_household_date ON transactions(household_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members full access"
  ON transactions FOR ALL
  USING (household_id = my_household_id())
  WITH CHECK (household_id = my_household_id());

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
