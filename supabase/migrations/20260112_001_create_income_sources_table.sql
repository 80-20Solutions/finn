-- Migration: 001_create_income_sources_table
CREATE TABLE income_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('salary', 'freelance', 'investment', 'other', 'custom')),
  custom_type_name VARCHAR(100),
  amount BIGINT NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_income_sources_user_id ON income_sources(user_id);
CREATE INDEX idx_income_sources_user_created ON income_sources(user_id, created_at DESC);

-- RLS Policies (Row-Level Security)
ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own income sources"
  ON income_sources FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own income sources"
  ON income_sources FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own income sources"
  ON income_sources FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own income sources"
  ON income_sources FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_income_sources_updated_at
  BEFORE UPDATE ON income_sources
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
