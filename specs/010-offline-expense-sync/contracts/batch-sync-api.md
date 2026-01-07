# API Contract: Batch Sync Endpoints

**Feature**: 010-offline-expense-sync
**Date**: 2026-01-07
**Purpose**: Define Supabase RPC functions for efficient batch synchronization

## Overview

The existing Supabase expense API uses single-record operations. For efficient offline sync (FR-016: max 10 expenses per batch), we need batch endpoints to minimize network round-trips and improve sync performance (SC-002: 30s for single expense, SC-003: 2min for 50 expenses).

**Backend Changes**: Minimal - create Supabase RPC (Remote Procedure Call) functions for batch operations.

---

## 1. Batch Create Expenses

### Endpoint
```sql
-- Supabase RPC function
CREATE OR REPLACE FUNCTION batch_create_expenses(
  p_expenses JSONB -- Array of expense objects
)
RETURNS JSONB -- Array of created expense IDs and any errors
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_expense JSONB;
  v_created_expense RECORD;
  v_user_id UUID;
  v_group_id UUID;
BEGIN
  -- Get current user and group
  v_user_id := auth.uid();
  SELECT group_id INTO v_group_id FROM profiles WHERE id = v_user_id;

  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'User not in a group';
  END IF;

  -- Process each expense in batch
  FOR v_expense IN SELECT * FROM jsonb_array_elements(p_expenses)
  LOOP
    BEGIN
      INSERT INTO expenses (
        id, user_id, group_id, amount, date, category_id, merchant, notes, is_group_expense, created_at, updated_at
      )
      VALUES (
        (v_expense->>'id')::UUID,
        v_user_id,
        v_group_id,
        (v_expense->>'amount')::DECIMAL,
        (v_expense->>'date')::TIMESTAMP,
        (v_expense->>'category_id')::UUID,
        v_expense->>'merchant',
        v_expense->>'notes',
        (v_expense->>'is_group_expense')::BOOLEAN,
        (v_expense->>'created_at')::TIMESTAMP,
        NOW()
      )
      RETURNING * INTO v_created_expense;

      v_result := v_result || jsonb_build_object(
        'id', v_created_expense.id,
        'status', 'success',
        'server_updated_at', v_created_expense.updated_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense->>'id',
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;
```

### Request (Dart)
```dart
final response = await supabase.rpc('batch_create_expenses', params: {
  'p_expenses': [
    {
      'id': 'uuid-1',
      'amount': 42.50,
      'date': '2026-01-07T10:30:00Z',
      'category_id': 'cat-uuid',
      'merchant': 'Coffee Shop',
      'notes': 'Morning coffee',
      'is_group_expense': true,
      'created_at': '2026-01-07T10:30:00Z',
    },
    {
      'id': 'uuid-2',
      'amount': 15.00,
      'date': '2026-01-07T12:00:00Z',
      'category_id': 'cat-uuid-2',
      'merchant': 'Lunch Place',
      'notes': null,
      'is_group_expense': false,
      'created_at': '2026-01-07T12:00:00Z',
    },
  ],
});
```

### Response
```json
[
  {
    "id": "uuid-1",
    "status": "success",
    "server_updated_at": "2026-01-07T10:31:23.456Z"
  },
  {
    "id": "uuid-2",
    "status": "error",
    "error_code": "23505",
    "error_message": "duplicate key value violates unique constraint"
  }
]
```

**Error Handling**:
- Individual failures don't abort entire batch
- Dart client retries failed items in next sync attempt
- Transaction rolled back only if entire RPC fails (auth error, etc.)

---

## 2. Batch Update Expenses

### Endpoint
```sql
CREATE OR REPLACE FUNCTION batch_update_expenses(
  p_updates JSONB -- Array of {id, fields_to_update, client_updated_at}
)
RETURNS JSONB -- Array of update results with conflict detection
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_update JSONB;
  v_existing RECORD;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
  LOOP
    BEGIN
      -- Check for conflicts (server version newer than client)
      SELECT * INTO v_existing
      FROM expenses
      WHERE id = (v_update->>'id')::UUID;

      IF NOT FOUND THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'error',
          'error_code', 'NOT_FOUND',
          'error_message', 'Expense not found (may have been deleted)'
        );
        CONTINUE;
      END IF;

      -- Conflict detection (FR-009: server wins)
      IF v_existing.updated_at > (v_update->>'client_updated_at')::TIMESTAMP THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'conflict',
          'server_version', row_to_json(v_existing),
          'server_updated_at', v_existing.updated_at,
          'client_updated_at', v_update->>'client_updated_at'
        );
        CONTINUE;
      END IF;

      -- No conflict - proceed with update
      UPDATE expenses
      SET
        amount = COALESCE((v_update->'fields'->>'amount')::DECIMAL, amount),
        date = COALESCE((v_update->'fields'->>'date')::TIMESTAMP, date),
        category_id = COALESCE((v_update->'fields'->>'category_id')::UUID, category_id),
        merchant = COALESCE(v_update->'fields'->>'merchant', merchant),
        notes = COALESCE(v_update->'fields'->>'notes', notes),
        is_group_expense = COALESCE((v_update->'fields'->>'is_group_expense')::BOOLEAN, is_group_expense),
        updated_at = NOW()
      WHERE id = (v_update->>'id')::UUID
      RETURNING updated_at INTO v_existing.updated_at;

      v_result := v_result || jsonb_build_object(
        'id', v_update->>'id',
        'status', 'success',
        'server_updated_at', v_existing.updated_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_update->>'id',
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;
```

### Request (Dart)
```dart
final response = await supabase.rpc('batch_update_expenses', params: {
  'p_updates': [
    {
      'id': 'existing-uuid-1',
      'client_updated_at': '2026-01-07T10:00:00Z', // Local modification time
      'fields': {
        'amount': 55.00, // Updated amount
        'merchant': 'Updated Coffee Shop',
      },
    },
  ],
});
```

### Response (Success)
```json
[
  {
    "id": "existing-uuid-1",
    "status": "success",
    "server_updated_at": "2026-01-07T10:32:45.789Z"
  }
]
```

### Response (Conflict - FR-009)
```json
[
  {
    "id": "existing-uuid-1",
    "status": "conflict",
    "server_version": {
      "id": "existing-uuid-1",
      "amount": 60.00,
      "merchant": "Coffee Shop - Family Member Edit",
      "updated_at": "2026-01-07T10:31:00Z"
    },
    "server_updated_at": "2026-01-07T10:31:00Z",
    "client_updated_at": "2026-01-07T10:00:00Z"
  }
]
```

**Dart Client Handling**:
```dart
if (result['status'] == 'conflict') {
  // Trigger conflict resolution (User Story 4)
  await _handleConflict(
    localVersion: offlineExpense,
    serverVersion: result['server_version'],
  );
}
```

---

## 3. Batch Delete Expenses

### Endpoint
```sql
CREATE OR REPLACE FUNCTION batch_delete_expenses(
  p_expense_ids UUID[] -- Array of expense IDs to delete
)
RETURNS JSONB -- Array of deletion results
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '[]'::JSONB;
  v_expense_id UUID;
  v_deleted BOOLEAN;
BEGIN
  FOREACH v_expense_id IN ARRAY p_expense_ids
  LOOP
    BEGIN
      DELETE FROM expenses
      WHERE id = v_expense_id
      AND user_id = auth.uid(); -- Security: user can only delete their own expenses

      GET DIAGNOSTICS v_deleted = ROW_COUNT;

      IF v_deleted > 0 THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'success'
        );
      ELSE
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'error',
          'error_code', 'NOT_FOUND',
          'error_message', 'Expense not found or not owned by user'
        );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        v_result := v_result || jsonb_build_object(
          'id', v_expense_id,
          'status', 'error',
          'error_code', SQLSTATE,
          'error_message', SQLERRM
        );
    END;
  END LOOP;

  RETURN v_result;
END;
$$;
```

### Request (Dart)
```dart
final response = await supabase.rpc('batch_delete_expenses', params: {
  'p_expense_ids': ['uuid-1', 'uuid-2', 'uuid-3'],
});
```

### Response
```json
[
  {"id": "uuid-1", "status": "success"},
  {"id": "uuid-2", "status": "success"},
  {"id": "uuid-3", "status": "error", "error_code": "NOT_FOUND", "error_message": "Expense not found or not owned by user"}
]
```

---

## 4. Get Expenses by IDs (for conflict resolution)

### Endpoint
```sql
CREATE OR REPLACE FUNCTION get_expenses_by_ids(
  p_expense_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(row_to_json(e.*))
  INTO v_result
  FROM expenses e
  WHERE e.id = ANY(p_expense_ids)
  AND e.group_id = (SELECT group_id FROM profiles WHERE id = auth.uid());

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;
```

**Purpose**: Fetch server versions of expenses for conflict resolution.

---

## Dart Client Implementation

### Sync Service
```dart
class BatchSyncService {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  Future<BatchSyncResult> syncBatch(List<SyncQueueItem> queueItems) async {
    final results = <String, SyncResult>{};

    // Group by operation type
    final creates = queueItems.where((i) => i.operation == 'create').toList();
    final updates = queueItems.where((i) => i.operation == 'update').toList();
    final deletes = queueItems.where((i) => i.operation == 'delete').toList();

    // Batch create
    if (creates.isNotEmpty) {
      final response = await _supabase.rpc('batch_create_expenses', params: {
        'p_expenses': creates.map((item) => jsonDecode(item.payload)).toList(),
      }) as List;

      for (final result in response) {
        results[result['id']] = SyncResult.fromJson(result);
      }
    }

    // Batch update
    if (updates.isNotEmpty) {
      final response = await _supabase.rpc('batch_update_expenses', params: {
        'p_updates': updates.map((item) {
          final payload = jsonDecode(item.payload);
          return {
            'id': item.entityId,
            'client_updated_at': payload['local_updated_at'],
            'fields': payload,
          };
        }).toList(),
      }) as List;

      for (final result in response) {
        results[result['id']] = SyncResult.fromJson(result);
        if (result['status'] == 'conflict') {
          await _handleConflict(result);
        }
      }
    }

    // Batch delete
    if (deletes.isNotEmpty) {
      final response = await _supabase.rpc('batch_delete_expenses', params: {
        'p_expense_ids': deletes.map((item) => item.entityId).toList(),
      }) as List;

      for (final result in response) {
        results[result['id']] = SyncResult.fromJson(result);
      }
    }

    return BatchSyncResult(results);
  }
}
```

---

## Performance Considerations

### Batch Size Limits (FR-016)
- **Client**: Maximum 10 expenses per batch
- **Server**: Postgres can handle 100+ easily, but limit client-side for progress feedback

### Transaction Isolation
- Each RPC runs in its own transaction
- Individual item failures don't rollback entire batch (resilience)
- Use `EXCEPTION` blocks to continue processing

### Network Efficiency (SC-002, SC-003)
- Single network round-trip for 10 expenses vs 10 round-trips
- Reduces sync time from ~5s per expense to ~30s for batch of 10
- Saves battery and bandwidth

### Rate Limiting (C-003)
- Supabase default: 60 requests/minute
- Batch API reduces from 500 requests (500 expenses) to 50 requests (50 batches of 10)
- Well within rate limits

---

## Error Handling Matrix

| Error Type | HTTP Code | Client Action |
|------------|-----------|---------------|
| **Auth failure** | 401 | Redirect to login |
| **Not in group** | 403 | Show "Join group first" |
| **Invalid UUID** | 400 | Mark item as permanently failed |
| **Duplicate key** | 23505 | Skip (already synced) |
| **Not found (update/delete)** | N/A | Log warning, continue |
| **Conflict (update)** | N/A | Trigger conflict resolution |
| **Network timeout** | N/A | Retry with exponential backoff |
| **Server error (5xx)** | 500 | Retry up to 3 times |

---

## Migration Path

### Phase 1: Create RPC Functions
```sql
-- Run via Supabase SQL Editor or migration
-- scripts/supabase/migrations/004_batch_sync_rpc.sql

CREATE OR REPLACE FUNCTION batch_create_expenses(...) ...;
CREATE OR REPLACE FUNCTION batch_update_expenses(...) ...;
CREATE OR REPLACE FUNCTION batch_delete_expenses(...) ...;
CREATE OR REPLACE FUNCTION get_expenses_by_ids(...) ...;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION batch_create_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION batch_update_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION batch_delete_expenses TO authenticated;
GRANT EXECUTE ON FUNCTION get_expenses_by_ids TO authenticated;
```

### Phase 2: Flutter Client Integration
- Add `BatchSyncService`
- Update `SyncQueueProcessor` to use batch endpoints
- Keep fallback to single-item API for backward compatibility

---

## Testing Contract

### Unit Tests (Supabase pgTAP)
```sql
-- Test batch create success
SELECT is(
  batch_create_expenses('[{"id": "test-uuid", "amount": 10.00, ...}]'::JSONB)->0->>'status',
  'success',
  'Batch create succeeds for valid expense'
);

-- Test conflict detection
SELECT is(
  batch_update_expenses('[{"id": "old-uuid", "client_updated_at": "2020-01-01", ...}]'::JSONB)->0->>'status',
  'conflict',
  'Update detects conflict when server version is newer'
);
```

### Integration Tests (Flutter)
```dart
testWidgets('Batch sync creates 10 expenses in < 5 seconds', (tester) async {
  final expenses = List.generate(10, (i) => _createMockExpense());
  final stopwatch = Stopwatch()..start();

  await syncService.syncBatch(expenses);

  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
});
```

---

## Backward Compatibility

- Existing single-expense endpoints remain unchanged
- Offline sync uses batch endpoints
- Non-offline flows (online expense creation) can continue using single endpoints or migrate gradually

---

## Security Checklist

- ✅ RLS (Row Level Security) policies enforced via `user_id = auth.uid()` checks
- ✅ SECURITY DEFINER functions run with elevated permissions but validate user
- ✅ SQL injection prevented via parameterized queries
- ✅ Group isolation enforced (users can only access expenses in their group)
- ✅ No sensitive data in error messages (generic messages only)

---

## Next Steps

1. ✅ Phase 0: Research complete
2. ✅ Phase 1: Data model complete
3. ✅ Phase 1: API contracts complete
4. ⏭️ Next: Create quickstart.md
5. ⏭️ Next: Update agent context
