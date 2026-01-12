-- Migration: Add wizard completion tracking to profiles table
-- Feature: Group Budget Setup Wizard (001-group-budget-wizard)
-- Task: T001
-- Date: 2026-01-09

-- Add budget_wizard_completed column to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS budget_wizard_completed BOOLEAN NOT NULL DEFAULT FALSE;

-- Create index for routing guards (frequent check on login)
-- Only indexes admin users since only they need wizard completion check
CREATE INDEX IF NOT EXISTS idx_profiles_wizard_completed
  ON public.profiles(id, budget_wizard_completed)
  WHERE is_group_admin = true;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.budget_wizard_completed IS
  'Tracks if group admin has completed mandatory budget setup wizard. Default FALSE ensures existing admins are prompted on first login after feature deployment.';
