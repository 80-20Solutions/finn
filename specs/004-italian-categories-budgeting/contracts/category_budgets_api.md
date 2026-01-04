# Category Budgets API Contract

**Feature**: 004-italian-categories-budgeting
**Service**: Supabase PostgreSQL REST API
**Date**: 2026-01-04

## Overview

API contracts for category budget management operations. All endpoints use Supabase PostgREST conventions with Row Level Security (RLS) enforced.

---

## Table: `category_budgets`

### Base Endpoint
```
/rest/v1/category_budgets
```

### Authentication
All requests require:
```http
Authorization: Bearer <supabase_jwt_token>
apikey: <supabase_anon_key>
```

---

## Operations

### 1. Get Category Budgets for Current Month

**Use Case**: Dashboard budget overview (FR-010)

**Request**:
```http
GET /rest/v1/category_budgets?select=*,expense_categories(name)&group_id=eq.<GROUP_ID>&year=eq.<YEAR>&month=eq.<MONTH>
```

**Response** (200 OK):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "category_id": "660e8400-e29b-41d4-a716-446655440000",
    "group_id": "770e8400-e29b-41d4-a716-446655440000",
    "amount": 50000,
    "month": 1,
    "year": 2026,
    "created_by": "880e8400-e29b-41d4-a716-446655440000",
    "created_at": "2026-01-04T10:00:00Z",
    "updated_at": "2026-01-04T10:00:00Z",
    "expense_categories": {
      "name": "Spesa"
    }
  }
]
```

**Error Responses**:
- `401 Unauthorized`: Missing or invalid JWT
- `403 Forbidden`: User not in group (RLS policy)

---

### 2. Create Category Budget

**Use Case**: Set budget for category (FR-003), Virgin category prompt (FR-007)

**Request**:
```http
POST /rest/v1/category_budgets
Content-Type: application/json

{
  "category_id": "660e8400-e29b-41d4-a716-446655440000",
  "group_id": "770e8400-e29b-41d4-a716-446655440000",
  "amount": 50000,
  "month": 1,
  "year": 2026,
  "created_by": "880e8400-e29b-41d4-a716-446655440000"
}
```

**Response** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "category_id": "660e8400-e29b-41d4-a716-446655440000",
  "group_id": "770e8400-e29b-41d4-a716-446655440000",
  "amount": 50000,
  "month": 1,
  "year": 2026,
  "created_by": "880e8400-e29b-41d4-a716-446655440000",
  "created_at": "2026-01-04T10:00:00Z",
  "updated_at": "2026-01-04T10:00:00Z"
}
```

**Validation**:
- `amount` >= 0 (CHECK constraint)
- `month` between 1-12 (CHECK constraint)
- `year` >= 2000 (CHECK constraint)
- UNIQUE(category_id, group_id, year, month)

**Error Responses**:
- `400 Bad Request`: Validation failure
- `409 Conflict`: Budget already exists for this category/month
- `403 Forbidden`: User not group admin (RLS policy)

---

### 3. Update Category Budget

**Use Case**: Modify existing budget (FR-003)

**Request**:
```http
PATCH /rest/v1/category_budgets?id=eq.<BUDGET_ID>
Content-Type: application/json

{
  "amount": 60000
}
```

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": 60000,
  "updated_at": "2026-01-04T11:00:00Z"
}
```

**Error Responses**:
- `403 Forbidden`: User not group admin
- `404 Not Found`: Budget doesn't exist

---

### 4. Delete Category Budget

**Use Case**: Remove budget for category (FR-029)

**Request**:
```http
DELETE /rest/v1/category_budgets?id=eq.<BUDGET_ID>
```

**Response** (204 No Content)

**Error Responses**:
- `403 Forbidden`: User not group admin
- `404 Not Found`: Budget doesn't exist

---

## RPC Functions

### 1. Get Category Budget Stats

**Function**: `get_category_budget_stats`

**Use Case**: Calculate current month spending vs. budget (FR-011, FR-012, FR-013)

**Request**:
```http
POST /rest/v1/rpc/get_category_budget_stats
Content-Type: application/json

{
  "p_group_id": "770e8400-e29b-41d4-a716-446655440000",
  "p_category_id": "660e8400-e29b-41d4-a716-446655440000",
  "p_year": 2026,
  "p_month": 1
}
```

**Response** (200 OK):
```json
{
  "budget_amount": 50000,
  "spent_amount": 32500,
  "remaining_amount": 17500,
  "percentage_used": 65.0,
  "is_over_budget": false,
  "expense_count": 15
}
```

**SQL Implementation**:
```sql
CREATE OR REPLACE FUNCTION get_category_budget_stats(
  p_group_id UUID,
  p_category_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE(
  budget_amount INTEGER,
  spent_amount INTEGER,
  remaining_amount INTEGER,
  percentage_used NUMERIC,
  is_over_budget BOOLEAN,
  expense_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_budget_amount INTEGER;
  v_spent_amount INTEGER;
  v_expense_count INTEGER;
  v_month_start DATE;
  v_month_end DATE;
BEGIN
  -- Calculate month boundaries
  v_month_start := make_date(p_year, p_month, 1);
  v_month_end := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Get budget amount
  SELECT amount INTO v_budget_amount
  FROM category_budgets
  WHERE group_id = p_group_id
    AND category_id = p_category_id
    AND year = p_year
    AND month = p_month;

  -- Get spending for month
  SELECT
    COALESCE(SUM(amount), 0),
    COUNT(*)
  INTO v_spent_amount, v_expense_count
  FROM expenses
  WHERE group_id = p_group_id
    AND category_id = p_category_id
    AND date >= v_month_start
    AND date <= v_month_end;

  -- Return stats
  RETURN QUERY SELECT
    COALESCE(v_budget_amount, 0),
    v_spent_amount,
    COALESCE(v_budget_amount, 0) - v_spent_amount,
    CASE
      WHEN v_budget_amount > 0 THEN (v_spent_amount::NUMERIC / v_budget_amount) * 100
      ELSE 0
    END,
    v_spent_amount > COALESCE(v_budget_amount, 0),
    v_expense_count;
END;
$$;
```

---

### 2. Get Overall Group Budget Stats

**Function**: `get_overall_group_budget_stats`

**Use Case**: Dashboard overall budget summary (FR-014)

**Request**:
```http
POST /rest/v1/rpc/get_overall_group_budget_stats
Content-Type: application/json

{
  "p_group_id": "770e8400-e29b-41d4-a716-446655440000",
  "p_year": 2026,
  "p_month": 1
}
```

**Response** (200 OK):
```json
{
  "total_budgeted": 500000,
  "total_spent": 325000,
  "total_remaining": 175000,
  "percentage_used": 65.0,
  "categories_over_budget": 2,
  "category_count": 10
}
```

**SQL Implementation**:
```sql
CREATE OR REPLACE FUNCTION get_overall_group_budget_stats(
  p_group_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE(
  total_budgeted INTEGER,
  total_spent INTEGER,
  total_remaining INTEGER,
  percentage_used NUMERIC,
  categories_over_budget INTEGER,
  category_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_budgeted INTEGER;
  v_total_spent INTEGER;
  v_month_start DATE;
  v_month_end DATE;
BEGIN
  -- Calculate month boundaries
  v_month_start := make_date(p_year, p_month, 1);
  v_month_end := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Sum all category budgets for this month
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total_budgeted
  FROM category_budgets
  WHERE group_id = p_group_id
    AND year = p_year
    AND month = p_month;

  -- Sum all expenses for this month (only categorized)
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total_spent
  FROM expenses
  WHERE group_id = p_group_id
    AND category_id IS NOT NULL
    AND date >= v_month_start
    AND date <= v_month_end;

  -- Count over-budget categories
  WITH category_spending AS (
    SELECT
      cb.category_id,
      cb.amount AS budget_amount,
      COALESCE(SUM(e.amount), 0) AS spent_amount
    FROM category_budgets cb
    LEFT JOIN expenses e
      ON e.category_id = cb.category_id
      AND e.group_id = cb.group_id
      AND e.date >= v_month_start
      AND e.date <= v_month_end
    WHERE cb.group_id = p_group_id
      AND cb.year = p_year
      AND cb.month = p_month
    GROUP BY cb.category_id, cb.amount
  )
  RETURN QUERY
  SELECT
    v_total_budgeted,
    v_total_spent,
    v_total_budgeted - v_total_spent,
    CASE
      WHEN v_total_budgeted > 0 THEN (v_total_spent::NUMERIC / v_total_budgeted) * 100
      ELSE 0
    END,
    (SELECT COUNT(*) FROM category_spending WHERE spent_amount > budget_amount)::INTEGER,
    (SELECT COUNT(DISTINCT category_id) FROM category_budgets
     WHERE group_id = p_group_id AND year = p_year AND month = p_month)::INTEGER;
END;
$$;
```

---

## Data Types

### Budget Amount
- **Type**: `INTEGER` (stored in cents)
- **Range**: 0 to 2,147,483,647 (max ~€21 million)
- **Examples**:
  - €50.00 → `5000`
  - €1,234.56 → `123456`

### Month/Year
- **month**: `INTEGER` (1-12)
- **year**: `INTEGER` (>= 2000)

---

## RLS Policies

### SELECT Policy
```sql
CREATE POLICY "Users can view their group category budgets"
  ON category_budgets FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );
```

### INSERT/UPDATE/DELETE Policy
```sql
CREATE POLICY "Group admins can manage category budgets"
  ON category_budgets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = category_budgets.group_id
        AND is_group_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = category_budgets.group_id
        AND is_group_admin = true
    )
  );
```

---

## Performance Expectations

| Operation | Target Latency | Notes |
|-----------|---------------|-------|
| Get budgets (current month) | <100ms | Indexed query |
| Create budget | <200ms | Single insert |
| Update budget | <200ms | Single update |
| Get budget stats (single) | <150ms | RPC with SUM aggregate |
| Get overall stats | <300ms | RPC with multiple aggregates |

---

## Related Contracts

- [User Category Usage API](./user_category_usage_api.md)
- [Orphaned Expenses API](./orphaned_expenses_api.md)
