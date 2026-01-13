import 'package:drift/drift.dart';

/// Drift table definition for group_expense_assignments
@DataClassName('GroupExpenseAssignmentData')
class GroupExpenseAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  IntColumn get spendingLimit => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
