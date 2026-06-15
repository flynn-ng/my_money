-- Revoke PUBLIC (which includes anon) execute from all security-sensitive functions
REVOKE EXECUTE ON FUNCTION public.create_household_for_user(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.my_household_id() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.remove_household_member(uuid, uuid) FROM PUBLIC;
