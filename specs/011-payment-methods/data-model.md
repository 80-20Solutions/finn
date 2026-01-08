# Data Model: Payment Methods

**Feature**: `011-payment-methods`
**Date**: 2026-01-07
**Purpose**: Complete data model definition for payment method tracking

## Entity Relationship Diagram

```
┌─────────────────────────┐
│   payment_methods       │
├─────────────────────────┤
│ id (PK)                 │◄──┐
│ name                    │   │
│ user_id (nullable)      │   │ ON DELETE RESTRICT
│ is_default              │   │
│ created_at              │   │
│ updated_at              │   │
└─────────────────────────┘   │
                              │
                              │
┌─────────────────────────┐   │
│   expenses              │   │
├─────────────────────────┤   │
│ id (PK)                 │   │
│ group_id (FK)           │   │
│ created_by (FK)         │   │
│ amount                  │   │
│ date                    │   │
│ category_id (FK)        │   │
│ payment_method_id (FK)  ├───┘
│ payment_method_name     │ (denormalized)
│ ...                     │
└─────────────────────────┘

┌─────────────────────────┐
│   users (auth.users)    │
├─────────────────────────┤
│ id (PK)                 │◄──────┐
│ email                   │       │
│ ...                     │       │ (user_id references)
└─────────────────────────┘       │
                                  │
                    ┌─────────────┴──────────────┐
                    │                            │
            payment_methods.user_id      expenses.created_by
```

## Entities

### PaymentMethodEntity (NEW)

**Purpose**: Represents a payment method available for expense tracking.

**Location**: `lib/features/payment_methods/domain/entities/payment_method_entity.dart`

#### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | No | Unique identifier |
| `name` | String (1-50 chars) | No | Display name (e.g., "Contanti", "PayPal") |
| `userId` | String (UUID) | Yes | Owner user ID (null for default methods) |
| `isDefault` | bool | No | true = predefined, false = custom |
| `createdAt` | DateTime | No | Timestamp when created |
| `updatedAt` | DateTime | No | Timestamp when last modified |
| `expenseCount` | int | Yes | Number of expenses using this method (optional, for UI) |

#### Business Rules

1. **Default Methods**:
   - `isDefault = true` AND `userId = null`
   - Cannot be modified or deleted
   - Visible to all users
   - Names: "Contanti", "Carta di Credito", "Bonifico", "Satispay"

2. **Custom Methods**:
   - `isDefault = false` AND `userId != null`
   - Can be created, updated, deleted by owner
   - Only visible to owner user
   - Unique per user (case-insensitive)

3. **Validation**:
   - Name: 1-50 characters, trimmed, non-empty
   - Uniqueness: (user_id, LOWER(name)) must be unique
   - Deletion: Blocked if `expenseCount > 0`

4. **Default Payment Method**:
   - "Contanti" is the default for new expenses
   - All existing expenses migrated to "Contanti"

#### Dart Implementation

```dart
class PaymentMethodEntity extends Equatable {
  final String id;
  final String name;
  final String? userId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? expenseCount;

  const PaymentMethodEntity({
    required this.id,
    required this.name,
    this.userId,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.expenseCount,
  });

  /// Factory for creating empty instance
  factory PaymentMethodEntity.empty() {
    return PaymentMethodEntity(
      id: '',
      name: '',
      userId: null,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expenseCount: null,
    );
  }

  /// Create a copy with updated fields
  PaymentMethodEntity copyWith({
    String? id,
    String? name,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expenseCount,
  }) {
    return PaymentMethodEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        userId,
        isDefault,
        createdAt,
        updatedAt,
        expenseCount,
      ];
}
```

---

### ExpenseEntity (MODIFIED)

**Purpose**: Represents a financial expense with payment method tracking.

**Location**: `lib/features/expenses/domain/entities/expense_entity.dart`

#### New Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `paymentMethodId` | String (UUID) | No | FK to payment_methods |
| `paymentMethodName` | String | Yes | Denormalized name for display |

#### Updated Dart Implementation (new fields only)

```dart
class ExpenseEntity extends Equatable {
  // ... existing fields ...
  final String paymentMethodId;      // NEW: Required
  final String? paymentMethodName;   // NEW: Optional (denormalized)

  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categoryName,
    required this.paymentMethodId,      // NEW
    this.paymentMethodName,             // NEW
    // ... other existing fields ...
  });

  // Updated copyWith to include new fields
  ExpenseEntity copyWith({
    String? id,
    // ... existing params ...
    String? paymentMethodId,
    String? paymentMethodName,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      // ... existing assignments ...
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        // ... existing props ...
        paymentMethodId,
        paymentMethodName,
      ];
}
```

#### Business Rules

1. **Required Field**:
   - Every expense MUST have a `paymentMethodId`
   - Enforced at database level (NOT NULL constraint)

2. **Default Value**:
   - New expenses default to "Contanti" payment method ID
   - Application sets default on expense creation

3. **Denormalization**:
   - `paymentMethodName` cached for display performance
   - Updated when payment method name changes
   - Can be null (lazily populated on read)

---

## Database Schema

### payment_methods Table

```sql
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL,
  user_id UUID,  -- References auth.users(id), NULL for default methods
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT chk_name_length CHECK (LENGTH(TRIM(name)) BETWEEN 1 AND 50),
  CONSTRAINT chk_default_no_user CHECK (
    (is_default = true AND user_id IS NULL) OR
    (is_default = false AND user_id IS NOT NULL)
  ),
  CONSTRAINT unique_user_payment_method UNIQUE (user_id, LOWER(name))
);

-- Indexes
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX idx_payment_methods_is_default ON payment_methods(is_default)
  WHERE is_default = true;

-- Trigger for updated_at
CREATE TRIGGER set_payment_methods_updated_at
  BEFORE UPDATE ON payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION trigger_set_updated_at();
```

#### Row-Level Security (RLS) Policies

```sql
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can view default methods + their own custom methods
CREATE POLICY "Users can view default payment methods"
  ON payment_methods FOR SELECT
  USING (is_default = true);

CREATE POLICY "Users can view their custom payment methods"
  ON payment_methods FOR SELECT
  USING (user_id = auth.uid());

-- INSERT: Users can only create their own custom methods
CREATE POLICY "Users can create their custom payment methods"
  ON payment_methods FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_default = false);

-- UPDATE: Users can only update their own custom methods
CREATE POLICY "Users can update their custom payment methods"
  ON payment_methods FOR UPDATE
  USING (user_id = auth.uid() AND is_default = false)
  WITH CHECK (user_id = auth.uid() AND is_default = false);

-- DELETE: Users can only delete their own custom methods
CREATE POLICY "Users can delete their custom payment methods"
  ON payment_methods FOR DELETE
  USING (user_id = auth.uid() AND is_default = false);
```

---

### expenses Table (Modifications)

```sql
-- Add new columns
ALTER TABLE expenses
  ADD COLUMN payment_method_id UUID,
  ADD COLUMN payment_method_name TEXT;

-- After migration, make NOT NULL
ALTER TABLE expenses
  ALTER COLUMN payment_method_id SET NOT NULL;

-- Foreign key constraint
ALTER TABLE expenses
  ADD CONSTRAINT fk_payment_method
  FOREIGN KEY (payment_method_id)
  REFERENCES payment_methods(id)
  ON DELETE RESTRICT;  -- Prevent deletion of methods in use

-- Index for queries filtering by payment method
CREATE INDEX idx_expenses_payment_method ON expenses(payment_method_id);
```

---

### Seed Data (Default Payment Methods)

```sql
-- Insert default payment methods (run once on database setup)
INSERT INTO payment_methods (id, name, user_id, is_default, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'Contanti', NULL, true, now(), now()),
  (gen_random_uuid(), 'Carta di Credito', NULL, true, now(), now()),
  (gen_random_uuid(), 'Bonifico', NULL, true, now(), now()),
  (gen_random_uuid(), 'Satispay', NULL, true, now(), now())
ON CONFLICT DO NOTHING;  -- Idempotent: skip if already exists
```

---

### Migration Script (Existing Expenses)

```sql
-- Migration to backfill existing expenses with "Contanti" payment method

-- Step 1: Ensure default "Contanti" method exists
INSERT INTO payment_methods (id, name, user_id, is_default)
VALUES (gen_random_uuid(), 'Contanti', NULL, true)
ON CONFLICT (user_id, LOWER(name)) DO NOTHING;

-- Step 2: Get "Contanti" method ID
DO $$
DECLARE
  contanti_id UUID;
BEGIN
  SELECT id INTO contanti_id
  FROM payment_methods
  WHERE name = 'Contanti' AND is_default = true
  LIMIT 1;

  -- Step 3: Update all expenses without payment method
  UPDATE expenses
  SET
    payment_method_id = contanti_id,
    payment_method_name = 'Contanti',
    updated_at = now()
  WHERE payment_method_id IS NULL;

  -- Step 4: Verify no NULL values remain
  IF EXISTS (SELECT 1 FROM expenses WHERE payment_method_id IS NULL) THEN
    RAISE EXCEPTION 'Migration failed: some expenses still have NULL payment_method_id';
  END IF;
END $$;

-- Step 5: Make column NOT NULL
ALTER TABLE expenses
  ALTER COLUMN payment_method_id SET NOT NULL;
```

---

## State Management Models

### PaymentMethodState

**Purpose**: UI state for payment method management.

**Location**: `lib/features/payment_methods/presentation/providers/payment_method_provider.dart`

```dart
class PaymentMethodState extends Equatable {
  final List<PaymentMethodEntity> paymentMethods;
  final bool isLoading;
  final String? errorMessage;

  const PaymentMethodState({
    this.paymentMethods = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Get default payment methods only
  List<PaymentMethodEntity> get defaultMethods =>
      paymentMethods.where((m) => m.isDefault).toList();

  /// Get custom payment methods only
  List<PaymentMethodEntity> get customMethods =>
      paymentMethods.where((m) => !m.isDefault).toList();

  /// Get payment method by ID
  PaymentMethodEntity? getById(String id) =>
      paymentMethods.firstWhereOrNull((m) => m.id == id);

  /// Get default "Contanti" method
  PaymentMethodEntity? get defaultContanti =>
      paymentMethods.firstWhereOrNull(
        (m) => m.name == 'Contanti' && m.isDefault,
      );

  /// Check if list is empty
  bool get isEmpty => paymentMethods.isEmpty;

  /// Check if has error
  bool get hasError => errorMessage != null;

  PaymentMethodState copyWith({
    List<PaymentMethodEntity>? paymentMethods,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PaymentMethodState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [paymentMethods, isLoading, errorMessage];
}
```

---

## JSON Serialization (Models)

### PaymentMethodModel

**Purpose**: Data transfer object for payment methods with JSON serialization.

**Location**: `lib/features/payment_methods/data/models/payment_method_model.dart`

```dart
class PaymentMethodModel extends PaymentMethodEntity {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    super.userId,
    required super.isDefault,
    required super.createdAt,
    required super.updatedAt,
    super.expenseCount,
  });

  /// From Supabase JSON response
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      isDefault: json['is_default'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expenseCount: json['expense_count'] as int?,
    );
  }

  /// To Supabase JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// From entity
  factory PaymentMethodModel.fromEntity(PaymentMethodEntity entity) {
    return PaymentMethodModel(
      id: entity.id,
      name: entity.name,
      userId: entity.userId,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expenseCount: entity.expenseCount,
    );
  }
}
```

---

### ExpenseModel (Modified)

**Purpose**: Updated expense model with payment method fields.

**Location**: `lib/features/expenses/data/models/expense_model.dart`

```dart
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.createdBy,
    required super.amount,
    required super.date,
    super.categoryId,
    super.categoryName,
    required super.paymentMethodId,      // NEW
    super.paymentMethodName,             // NEW
    // ... other existing fields ...
  });

  /// From Supabase JSON (updated)
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      createdBy: json['created_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      paymentMethodId: json['payment_method_id'] as String,     // NEW
      paymentMethodName: json['payment_method_name'] as String?, // NEW
      // ... other existing fields ...
    );
  }

  /// To Supabase JSON (updated)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'created_by': createdBy,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'category_name': categoryName,
      'payment_method_id': paymentMethodId,      // NEW
      'payment_method_name': paymentMethodName,  // NEW
      // ... other existing fields ...
    };
  }
}
```

---

## Validation Rules

### Payment Method Name Validation

```dart
class PaymentMethodValidation {
  static const int minLength = 1;
  static const int maxLength = 50;

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Payment method name is required';
    }

    final trimmed = name.trim();

    if (trimmed.length < minLength) {
      return 'Payment method name must be at least $minLength character';
    }

    if (trimmed.length > maxLength) {
      return 'Payment method name must be at most $maxLength characters';
    }

    return null;  // Valid
  }
}
```

---

## Query Patterns

### Common Queries

1. **Get all payment methods for user** (default + custom):
   ```sql
   SELECT * FROM payment_methods
   WHERE is_default = true
      OR user_id = $1
   ORDER BY is_default DESC, name ASC;
   ```

2. **Get payment method by ID**:
   ```sql
   SELECT * FROM payment_methods
   WHERE id = $1;
   ```

3. **Check if name exists for user** (case-insensitive):
   ```sql
   SELECT COUNT(*) FROM payment_methods
   WHERE user_id = $1
     AND LOWER(name) = LOWER($2)
     AND id != $3;  -- Exclude current method (for edit)
   ```

4. **Count expenses using payment method**:
   ```sql
   SELECT COUNT(*) FROM expenses
   WHERE payment_method_id = $1;
   ```

5. **Get payment methods with expense counts**:
   ```sql
   SELECT
     pm.*,
     COUNT(e.id) as expense_count
   FROM payment_methods pm
   LEFT JOIN expenses e ON e.payment_method_id = pm.id
   WHERE pm.is_default = true OR pm.user_id = $1
   GROUP BY pm.id
   ORDER BY pm.is_default DESC, pm.name ASC;
   ```

---

## Data Integrity Constraints

### Database-Level

1. **Primary Keys**: Unique UUID for all records
2. **Foreign Keys**:
   - `payment_methods.user_id` → `auth.users(id)` (optional)
   - `expenses.payment_method_id` → `payment_methods(id)` (required, ON DELETE RESTRICT)
3. **Unique Constraints**:
   - `(user_id, LOWER(name))` - Prevents duplicate names per user
4. **Check Constraints**:
   - `name` length: 1-50 characters (trimmed)
   - Default methods: `is_default=true` ⇒ `user_id=null`
   - Custom methods: `is_default=false` ⇒ `user_id NOT NULL`

### Application-Level

1. **Required Fields**: All non-nullable fields must be provided
2. **Validation**: Name trimmed before insert/update
3. **Duplicate Check**: Case-insensitive name comparison before save
4. **Delete Protection**: Check expense count before delete

---

## Indexes for Performance

| Index | Columns | Purpose |
|-------|---------|---------|
| `PRIMARY KEY` | `id` | Unique identifier lookup |
| `idx_payment_methods_user_id` | `user_id` (partial: WHERE user_id IS NOT NULL) | Filter by user |
| `idx_payment_methods_is_default` | `is_default` (partial: WHERE is_default = true) | Filter defaults |
| `idx_expenses_payment_method` | `payment_method_id` | Expense lookups, count queries |

---

## Migration Checklist

- [ ] Create `payment_methods` table
- [ ] Seed default payment methods
- [ ] Add `payment_method_id` column to `expenses` (nullable)
- [ ] Add `payment_method_name` column to `expenses` (nullable)
- [ ] Backfill existing expenses with "Contanti"
- [ ] Verify all expenses have payment_method_id
- [ ] Make `payment_method_id` NOT NULL
- [ ] Add foreign key constraint
- [ ] Add indexes
- [ ] Enable RLS on `payment_methods`
- [ ] Create RLS policies
- [ ] Test queries with sample data
- [ ] Verify migration rollback script

---

## Next Steps

1. Generate API contracts (`contracts/payment_methods_schema.yaml`)
2. Create quickstart guide for developers
3. Implement domain entities and repositories
4. Implement data models and datasources
5. Create presentation layer (providers, screens, widgets)
6. Write tests

