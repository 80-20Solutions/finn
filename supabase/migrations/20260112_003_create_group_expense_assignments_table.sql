-- Migration: 003_create_group_expense_assignments_table
CREATE TABLE group_expense_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  spending_limit BIGINT NOT NULL CHECK (spending_limit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Indexes
CREATE INDEX idx_group_expense_assignments_user ON group_expense_assignments(user_id);
CREATE INDEX idx_group_expense_assignments_group ON group_expense_assignments(group_id);

-- RLS Policies
ALTER TABLE group_expense_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own assignments"
  ON group_expense_assignments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Group admins can manage assignments"
  ON group_expense_assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM family_groups
      WHERE family_groups.id = group_expense_assignments.group_id
      AND family_groups.created_by = auth.uid()
    )
  );

-- Trigger for updated_at
CREATE TRIGGER update_group_expense_assignments_updated_at
  BEFORE UPDATE ON group_expense_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
