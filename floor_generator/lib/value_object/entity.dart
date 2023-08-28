import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:floor_generator/value_object/field.dart';
import 'package:floor_generator/value_object/foreign_key.dart';
import 'package:floor_generator/value_object/index.dart';
import 'package:floor_generator/value_object/primary_key.dart';
import 'package:floor_generator/value_object/queryable.dart';

import 'fts.dart';

class Entity extends Queryable {
  final PrimaryKey primaryKey;
  final List<ForeignKey> foreignKeys;
  final List<Index> indices;
  final bool withoutRowid;
  final String valueMapping;
  final Fts? fts;
  final String insertValueMapping;

  Entity(
    ClassElement classElement,
    String name,
    List<Field> fields,
    this.primaryKey,
    this.foreignKeys,
    this.indices,
    this.withoutRowid,
    String constructor,
    this.valueMapping,
    this.fts, {
    String? insertValueMapping,
  })  : this.insertValueMapping = insertValueMapping ?? valueMapping,
        super(classElement, name, fields, constructor);

  String getCreateTableStatement() {
    final databaseDefinition = <String>[];
    var hasFtsRowid = false;
    for (final field in fields) {
      if (fts != null && !hasFtsRowid && field.columnName == 'rowid') {
        if (field.sqlType != 'INTEGER') {
          throw 'A `rowid` field must be of type: INTEGER';
        }
        hasFtsRowid = true;
        continue;
      }
      databaseDefinition.add(
        field.getDatabaseDefinition(
          primaryKey.autoGenerateId && primaryKey.fields.contains(field),
        ),
      );
    }

    if (foreignKeys.isNotEmpty) {
      databaseDefinition.addAll(
        foreignKeys.map((foreignKey) => foreignKey.getDefinition()),
      );
    }

    final pkDefinition = hasFtsRowid ? null : _createPrimaryKeyDefinition();
    if (pkDefinition != null) {
      databaseDefinition.add(pkDefinition);
    }

    if (fts == null) {
      return 'CREATE TABLE IF NOT EXISTS `$name` (${databaseDefinition.join(', ')})${withoutRowid ? ' WITHOUT ROWID' : ''}';
    } else {
      final tco = fts!.tableCreateOption();
      if (tco.isNotEmpty) {
        databaseDefinition.add(tco);
      }
      return 'CREATE VIRTUAL TABLE IF NOT EXISTS `$name` ${fts!.usingOption}(${databaseDefinition.join(', ')})';
    }
  }

  String? _createPrimaryKeyDefinition() {
    if (primaryKey.autoGenerateId) {
      return null;
    } else {
      final columns =
          primaryKey.fields.map((field) => '`${field.columnName}`').join(', ');
      return 'PRIMARY KEY ($columns)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          classElement == other.classElement &&
          name == other.name &&
          fields.equals(other.fields) &&
          primaryKey == other.primaryKey &&
          foreignKeys.equals(other.foreignKeys) &&
          indices.equals(other.indices) &&
          withoutRowid == other.withoutRowid &&
          constructor == other.constructor &&
          valueMapping == other.valueMapping;

  @override
  int get hashCode =>
      classElement.hashCode ^
      name.hashCode ^
      fields.hashCode ^
      primaryKey.hashCode ^
      foreignKeys.hashCode ^
      indices.hashCode ^
      constructor.hashCode ^
      withoutRowid.hashCode ^
      fts.hashCode ^
      valueMapping.hashCode;

  @override
  String toString() {
    return 'Entity{classElement: $classElement, name: $name, fields: $fields, primaryKey: $primaryKey, foreignKeys: $foreignKeys, indices: $indices, constructor: $constructor, withoutRowid: $withoutRowid, valueMapping: $valueMapping, fts: $fts}';
  }
}
