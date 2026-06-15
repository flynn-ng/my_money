-- Money sources: wallets, bank accounts, cash, properties, investments, etc.

CREATE TABLE IF NOT EXISTS money_sources (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  uuid        NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name          text        NOT NULL,
  type          text        NOT NULL DEFAULT 'cash'
                            CHECK (type IN ('cash', 'bank', 'property', 'investment', 'other')),
  icon          text        NOT NULL DEFAULT '💳',
  color         text        NOT NULL DEFAULT '#2196F3',
  initial_balance numeric   NOT NULL DEFAULT 0,
  currency      text        NOT NULL DEFAULT 'VND',
  is_archived   boolean     NOT NULL DEFAULT false,
  sort_order    int         NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE money_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "household members can manage money_sources"
  ON money_sources
  FOR ALL
  USING  (household_id = my_household_id())
  WITH CHECK (household_id = my_household_id());

-- Link transactions to a money source (nullable so existing rows are unaffected)
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS source_id uuid REFERENCES money_sources(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_source_id ON transactions(source_id);
