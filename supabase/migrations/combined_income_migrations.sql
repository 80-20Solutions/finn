-- ============================================
-- Combined Migration: Income Management Tables
-- ============================================
-- Execute this in Supabase SQL Editor
-- Dashboard -> SQL Editor -> New Query -> Paste and Run
-- ============================================

-- Migration 1: Create income_sources table
-- ============================================

CREATE TABLE IF NOT EXISTS income_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('salary', 'freelance', 'investment', 'other', 'custom')),
  custom_type_name VARCHAR(100),
  amount BIGINT NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_income_sources_user_id ON income_sources(user_id);
CREATE INDEX IF NOT EXISTS idx_income_sources_user_created ON income_sources(user_id, created_at DESC);

-- RLS Policies (Row-Level Security)
ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own income sources" ON income_sources;
CREATE POLICY "Users can view their own income sources"
  ON income_sources FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own income sources" ON income_sources;
CREATE POLICY "Users can insert their own income sources"
  ON income_sources FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own income sources" ON income_sources;
CREATE POLICY "Users can update their own income sources"
  ON income_sources FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own income sources" ON income_sources;
CREATE POLICY "Users can delete their own income sources"
  ON income_sources FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for auto-updating updated_at (reuse existing function if it exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_income_sources_updated_at ON income_sources;
CREATE TRIGGER update_income_sources_updated_at
  BEFORE UPDATE ON income_sources
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


-- Migration 2: Create savings_goals table
-- ============================================

CREATE TABLE IF NOT EXISTS savings_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL CHECK (amount >= 0),
  original_amount BIGINT CHECK (original_amount >= 0),
  adjusted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals(user_id);

-- RLS Policies
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own savings goal" ON savings_goals;
CREATE POLICY "Users can view their own savings goal"
  ON savings_goals FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own savings goal" ON savings_goals;
CREATE POLICY "Users can insert their own savings goal"
  ON savings_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own savings goal" ON savings_goals;
CREATE POLICY "Users can update their own savings goal"
  ON savings_goals FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own savings goal" ON savings_goals;
CREATE POLICY "Users can delete their own savings goal"
  ON savings_goals FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_savings_goals_updated_at ON savings_goals;
CREATE TRIGGER update_savings_goals_updated_at
  BEFORE UPDATE ON savings_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


-- Migration 3: Create group_expense_assignments table
-- ============================================

CREATE TABLE IF NOT EXISTS group_expense_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  spending_limit BIGINT NOT NULL CHECK (spending_limit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_group_expense_assignments_user ON group_expense_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_group_expense_assignments_group ON group_expense_assignments(group_id);

-- RLS Policies
ALTER TABLE group_expense_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own assignments" ON group_expense_assignments;
CREATE POLICY "Users can view their own assignments"
  ON group_expense_assignments FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Group admins can manage assignments" ON group_expense_assignments;
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
DROP TRIGGER IF EXISTS update_group_expense_assignments_updated_at ON group_expense_assignments;
CREATE TRIGGER update_group_expense_assignments_updated_at
  BEFORE UPDATE ON group_expense_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Migration Complete!
-- ============================================
-- You can now test the income management feature in the app
