import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';

final catalogDaoProvider =
    Provider<CatalogDao>((ref) => CatalogDao(ref.watch(appDatabaseProvider)));

final operationsDaoProvider = Provider<OperationsDao>(
    (ref) => OperationsDao(ref.watch(appDatabaseProvider)));
