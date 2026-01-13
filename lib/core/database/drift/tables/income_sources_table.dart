import 'package:drift/drift.dart';
import '../../../../features/budgets/domain/entities/income_source_entity.dart';

/// Drift table definition for income_sources
@DataClassName('IncomeSourceData')
class IncomeSources extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => textEnum<IncomeType>()();
  TextColumn get customTypeName => text().nullable()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
