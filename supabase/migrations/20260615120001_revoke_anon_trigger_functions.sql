-- Revoke anon/public execute from trigger functions re-granted by CREATE OR REPLACE
REVOKE EXECUTE ON FUNCTION public.update_goal_current_amount() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.check_transaction_rate_limit() FROM anon, PUBLIC;
