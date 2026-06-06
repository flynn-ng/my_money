CREATE TABLE savings_goals (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id   uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name           text NOT NULL,
  icon           text NOT NULL DEFAULT '🏦',
  target_amount  numeric(12, 2) NOT NULL CHECK (target_amount > 0),
  current_amount numeric(12, 2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  deadline       date,
  is_completed   boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE savings_contributions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id    uuid NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  added_by   uuid NOT NULL REFERENCES profiles(id),
  amount     numeric(12, 2) NOT NULL CHECK (amount != 0),
  date       date NOT NULL DEFAULT current_date,
  notes      text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members full access"
  ON savings_goals FOR ALL
  USING (household_id = my_household_id())
  WITH CHECK (household_id = my_household_id());

ALTER TABLE savings_contributions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "household members full access"
  ON savings_contributions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM savings_goals g
      WHERE g.id = goal_id AND g.household_id = my_household_id()
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE savings_goals;
