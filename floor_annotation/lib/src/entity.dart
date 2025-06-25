import 'package:floor_annotation/src/foreign_key.dart';
import 'package:floor_annotation/src/index.dart';

/// Marks a class as a database entity (table).
class Entity {
  /// The table name of the SQLite table.
  final String? tableName;

  /// List of indices on the table.
  final List<Index> indices;

  /// List of [ForeignKey] constraints on this entity.
  final List<ForeignKey> foreignKeys;

  /// List of primary key column names.
  final List<String> primaryKeys;
  
  /// Defines multiple tables inheriting the same structure as base table.
  /// The base table name is prepended with the map key as prefix
  /// Examples:
  /// ```
  /// tableName: 'person',
  /// indices: [
  ///   Index(value: ['name']),
  /// ],
  /// prefixes: {
  ///   'copy_idx_': null,
  ///   'empty_idx_': [],
  ///   'custom_idx_': [
  ///     Index(value: ['admin', 'name']),
  ///   ],
  /// },
  /// ```
  /// Tables outputs:
  /// 1. copy_idx_person - has the same secondary index as base table
  /// 2. empty_idx_person - has no secondary index
  /// 3. custom_idx_person - has a single secondary index with the fields 'admin' and 'name' as composite keys
  final Map<String, List<Index>?> prefixes;

  /// Whether the table is a "WITHOUT ROWID table".
  final bool withoutRowid;

  /// Marks a class as a database entity (table).
  const Entity({
    this.tableName,
    this.indices = const [],
    this.foreignKeys = const [],
    this.primaryKeys = const [],
    this.prefixes = const {},
    this.withoutRowid = false,
  });
}

/// Marks a class as a database entity (table).
const entity = Entity();
