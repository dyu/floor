import 'dart:async';

import 'package:floor/src/extension/on_conflict_strategy_extensions.dart';
import 'package:floor/src/util/primary_key_helper.dart';
import 'package:floor_annotation/floor_annotation.dart';
import 'package:sqflite_common/sqlite_api.dart';

class UpdateAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final List<String> _primaryKeyColumnName;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  UpdateAdapter(
    final DatabaseExecutor database,
    final String entityName,
    final List<String> primaryKeyColumnName,
    final Map<String, Object?> Function(T) valueMapper, [
    final StreamController<String>? changeListener,
  ])  : assert(entityName.isNotEmpty),
        assert(primaryKeyColumnName.isNotEmpty),
        _database = database,
        _entityName = entityName,
        _valueMapper = valueMapper,
        _primaryKeyColumnName = primaryKeyColumnName,
        _changeListener = changeListener;

  Future<void> update(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    await _update(item, onConflictStrategy, prefix: prefix);
  }

  Future<void> updateList(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    if (items.isEmpty) return;
    await _updateList(items, onConflictStrategy, prefix: prefix);
  }

  Future<int> updateAndReturnChangedRows(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) {
    return _update(item, onConflictStrategy, prefix: prefix);
  }

  Future<int> updateListAndReturnChangedRows(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    if (items.isEmpty) return 0;
    return _updateList(items, onConflictStrategy, prefix: prefix);
  }

  Future<int> _update(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final values = _valueMapper(item);

    final result = await _database.update(
      entityName,
      values,
      where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnName),
      whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
        _primaryKeyColumnName,
        values,
      ),
      conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
    );
    if (result != 0) _changeListener?.add(entityName);
    return result;
  }

  Future<int> _updateList(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final batch = _database.batch();
    for (final item in items) {
      final values = _valueMapper(item);

      batch.update(
        entityName,
        values,
        where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnName),
        whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
          _primaryKeyColumnName,
          values,
        ),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(entityName);
    return result.isNotEmpty
        ? result.reduce((sum, element) => sum + element)
        : 0;
  }
}
