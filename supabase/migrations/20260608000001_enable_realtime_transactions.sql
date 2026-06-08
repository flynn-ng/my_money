-- Enable Supabase Realtime for the transactions table so partners
-- receive live updates when the other person adds/edits/deletes a transaction.
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
