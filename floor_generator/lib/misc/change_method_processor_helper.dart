import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/value_object/entity.dart';
import 'package:source_gen/source_gen.dart';

/*
const _emptyStringLiterals = ["''", '""'];
bool _isOptionalPositionalString(ParameterElement e) {
  return e.isOptionalPositional && null == e.defaultValueCode &&
      _emptyStringLiterals.contains(e.defaultValueCode);
}

bool _isOptionalPositionalString(ParameterElement e) {
  return e.isOptionalPositional &&
      e.type.isDartCoreString &&
      !e.hasDefaultValue;
}
*/

bool _isOptionalNamedString(ParameterElement e, String name) {
  return e.isOptionalNamed && name == e.name && !e.hasDefaultValue;
}

/// Groups common functionality of change method processors.
class ChangeMethodProcessorHelper {
  final MethodElement _methodElement;
  final List<Entity> _entities;

  const ChangeMethodProcessorHelper(
    final MethodElement methodElement,
    final List<Entity> entities,
  )   : _methodElement = methodElement,
        _entities = entities;

  Entity getParameterEntity() {
    final parameters = _methodElement.parameters;
    if (parameters.isEmpty) {
      throw InvalidGenerationSourceError(
        'There is no parameter supplied for this method. Please add one.',
        element: _methodElement,
      );
    }
    final parameterElement = parameters.first;
    final flattenedParameterType = getFlattenedParameterType(parameterElement);
    final entity = getEntity(flattenedParameterType);
    
    if (parameters.length > 2) {
      throw InvalidGenerationSourceError(
        entity.prefixes.isEmpty
            ? 'Only one parameter is allowed on this.'
            : 'A max of 2 parameters are allowed on this.',
        element: _methodElement,
      );
    }
    
    if (parameters.length != 1) {
      if (entity.prefixes.isEmpty) {
        throw InvalidGenerationSourceError(
          'Only one parameter is allowed on this.',
          element: _methodElement,
        );
      }
      if (!_isOptionalNamedString(parameters.last, 'prefix')) {
        throw InvalidGenerationSourceError(
          'The trailing parameter allowed on this can only be an optional string.',
          element: _methodElement,
        );
      }
    }
    
    return entity;
  }

  ParameterElement getParameterElement() {
    final parameters = _methodElement.parameters;
    if (parameters.isEmpty) {
      throw InvalidGenerationSourceError(
        'There is no parameter supplied for this method. Please add one.',
        element: _methodElement,
      );
    } else if (parameters.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one parameter is allowed on this.',
        element: _methodElement,
      );
    }
    return parameters.first;
  }

  DartType getFlattenedParameterType(
    final ParameterElement parameterElement,
  ) {
    final changesMultipleItems = parameterElement.type.isDartCoreList;

    return changesMultipleItems
        ? parameterElement.type.flatten()
        : parameterElement.type;
  }

  Entity getEntity(final DartType flattenedParameterType) {
    return _entities.firstWhere(
        (entity) =>
            entity.classElement.displayName ==
            flattenedParameterType.getDisplayString(withNullability: false),
        orElse: () => throw InvalidGenerationSourceError(
            'You are trying to change an object which is not an entity.',
            element: _methodElement));
  }
}
