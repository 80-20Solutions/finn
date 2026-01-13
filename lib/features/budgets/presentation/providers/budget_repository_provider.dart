import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/budget_remote_datasource.dart';
import '../../data/datasources/budget_local_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../../offline/data/local/offline_database.dart';

/// Provider for Supabase client
final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for offline database
final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  return OfflineDatabase();
});

/// Provider for budget remote datasource
final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSourceImpl(
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provider for budget local datasource
final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  return BudgetLocalDataSourceImpl(
    ref.watch(offlineDatabaseProvider),
  );
});

/// Provider for budget repository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    remoteDataSource: ref.watch(budgetRemoteDataSourceProvider),
    localDataSource: ref.watch(budgetLocalDataSourceProvider),
  );
});
