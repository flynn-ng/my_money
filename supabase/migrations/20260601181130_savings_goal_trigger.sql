
-- Atomically update savings_goal current_amount when a contribution is inserted
CREATE OR REPLACE FUNCTION update_goal_current_amount()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE savings_goals
  SET
    current_amount = current_amount + NEW.amount,
    is_completed   = (current_amount + NEW.amount >= target_amount)
  WHERE id = NEW.goal_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_contribution_insert
AFTER INSERT ON savings_contributions
FOR EACH ROW EXECUTE FUNCTION update_goal_current_amount();
