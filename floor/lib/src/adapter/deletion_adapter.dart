import 'dart:async';

import 'package:floor/src/util/primary_key_helper.dart';
import 'package:sqflite_common/sqlite_api.dart' show DatabaseExecutor;

class DeletionAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final List<String> _primaryKeyColumnNames;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  DeletionAdapter(
    final DatabaseExecutor database,
    final String entityName,
    final List<String> primaryKeyColumnName,
    final Map<String, Object?> Function(T) valueMapper, [
    final StreamController<String>? changeListener,
  ])  : assert(entityName.isNotEmpty),
        assert(primaryKeyColumnName.isNotEmpty),
        _database = database,
        _entityName = entityName,
        _primaryKeyColumnNames = primaryKeyColumnName,
        _valueMapper = valueMapper,
        _changeListener = changeListener;

  Future<void> delete(final T item, {
    String? prefix,
  }) async {
    await _delete(item, prefix: prefix);
  }

  Future<void> deleteList(final List<T> items, {
    String? prefix,
  }) async {
    if (items.isEmpty) return;
    await _deleteList(items, prefix: prefix);
  }

  Future<int> deleteAndReturnChangedRows(final T item, {
    String? prefix,
  }) {
    return _delete(item, prefix: prefix);
  }

  Future<int> deleteListAndReturnChangedRows(final List<T> items, {
    String? prefix,
  }) async {
    if (items.isEmpty) return 0;
    return _deleteList(items, prefix: prefix);
  }

  Future<int> _delete(final T item, {
    String? prefix,
  }) async {
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final result = await _database.delete(
      entityName,
      where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnNames),
      whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
        _primaryKeyColumnNames,
        _valueMapper(item),
      ),
    );
    if (result != 0) _changeListener?.add(entityName);
    return result;
  }

  Future<int> _deleteList(final List<T> items, {
    String? prefix,
  }) async {
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final batch = _database.batch();
    for (final item in items) {
      batch.delete(
        entityName,
        where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnNames),
        whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
          _primaryKeyColumnNames,
          _valueMapper(item),
        ),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(entityName);
    return result.isNotEmpty
        ? result.reduce((sum, element) => sum + element)
        : 0;
  }
}
