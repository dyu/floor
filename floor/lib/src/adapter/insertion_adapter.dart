import 'dart:async';

import 'package:floor/src/extension/on_conflict_strategy_extensions.dart';
import 'package:floor_annotation/floor_annotation.dart';
import 'package:sqflite_common/sqlite_api.dart';

class InsertionAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  InsertionAdapter(
    final DatabaseExecutor database,
    final String entityName,
    final Map<String, Object?> Function(T) valueMapper, [
    final StreamController<String>? changeListener,
  ])  : assert(entityName.isNotEmpty),
        _database = database,
        _entityName = entityName,
        _valueMapper = valueMapper,
        _changeListener = changeListener;

  Future<void> insert(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    await _insert(item, onConflictStrategy, prefix: prefix);
  }

  Future<void> insertList(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    if (items.isEmpty) return;
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    await batch.commit(noResult: true);
    _changeListener?.add(entityName);
  }

  Future<int> insertAndReturnId(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) {
    return _insert(item, onConflictStrategy, prefix: prefix);
  }

  Future<List<int>> insertListAndReturnIds(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    if (items.isEmpty) return [];
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(entityName);
    return result;
  }

  Future<int> _insert(
    final T item,
    final OnConflictStrategy onConflictStrategy, {
    String? prefix,
  }) async {
    final entityName = prefix == null ? _entityName : '$prefix$_entityName';
    final result = await _database.insert(
      entityName,
      _valueMapper(item),
      conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
    );
    if (result != 0) _changeListener?.add(entityName);
    return result;
  }
}
