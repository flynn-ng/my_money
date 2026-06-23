-- Data correction: clear all wallet links from existing transactions and drop the FK.
-- Wallets (money_sources) and transactions are now fully independent.

UPDATE transactions SET source_id = NULL WHERE source_id IS NOT NULL;

DROP INDEX IF EXISTS idx_transactions_source_id;

ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_source_id_fkey;
