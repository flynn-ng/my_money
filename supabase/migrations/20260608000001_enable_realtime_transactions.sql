-- Enable Supabase Realtime for the transactions table so partners
-- receive live updates when the other person adds/edits/deletes a transaction.
-- Guard against the table already being in the publication (SQLSTATE 42710).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'transactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
  END IF;
END $$;
