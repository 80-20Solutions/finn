import 'package:drift/drift.dart';

/// Drift table definition for savings_goals
@DataClassName('SavingsGoalData')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get amount => integer()();
  IntColumn get originalAmount => integer().nullable()();
  DateTimeColumn get adjustedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
