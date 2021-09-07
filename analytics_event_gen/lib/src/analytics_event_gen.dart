import 'dart:async';

import 'package:analytics_event/analytics_event.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

abstract class GeneratorForImplementers<T> extends Generator {
  TypeChecker get typeChecker => TypeChecker.fromRuntime(T);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    for (final element in library.allElements) {
      if (element is ClassElement && needsGenerate(element)) {
        final generatedValue = generateForElement(element, buildStep);
        for (final value in [generatedValue]) {
          assert(value.length == value.trim().length);
          values.add(value);
        }
      }
    }

    if (values.isEmpty) {
      return '';
    }

    return '// ignore_for_file: unnecessary_statements\n\n' +
        values.join('\n\n');
  }

  String generateForElement(Element element, BuildStep buildStep);

  bool needsGenerate(ClassElement classElement) {
    return typeChecker.isAssignableFrom(classElement);
  }
}

//class AnalyticsEventGenerator extends GeneratorForAnnotation<AnalyticsEventStubs> {
class AnalyticsEventGenerator
    extends GeneratorForImplementers<AnalyticsEventStubs> {
  AnalyticsEventGenerator({required this.useNullSafetySyntax});

  static const _override = Reference('override');
  static const _trackerFieldName = 'tracker';

  /// internal method which forwards to [_trackerFieldName] if it is defined.
  static const _trackEventMethodName = 'trackEvent';
  static const _trackAnalyticsFunc = Reference('TrackAnalytics');
  static const _registerTrackerFunc = Reference('registerTracker');
  static const _removeEventPrefix = ['_track', 'track'];

  bool useNullSafetySyntax;

  Parameter _toParameter(ParameterElement parameter) {
    final nullable =
        parameter.type.nullabilitySuffix == NullabilitySuffix.question;
    return Parameter(
      (pb) => pb
        ..name = parameter.name
        ..type = refer(parameter.type.element!.name!).asNullable(nullable)
        ..required = parameter.isNamed && parameter.isRequiredNamed
        ..named = parameter.isNamed
        ..defaultTo = parameter.defaultValueCode == null
            ? null
            : Code(parameter.defaultValueCode!),
    );
  }

  @override
  String generateForElement(Element element, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.name;
      throw InvalidGenerationSourceError('Generator cannot target `$name`.',
          todo: 'Remove the $AnalyticsEventStubs annotation from `$name`.',
          element: element);
    }
    final classElement = element;
    final result = StringBuffer();

    result.writeln('// got to generate for ${element.name}');

    final methods = classElement.methods
        .where((method) => method.isAbstract)
        .map((method) => Method.returnsVoid((mb) => mb
              ..name = method.name
              ..annotations.add(_override)
              ..requiredParameters.addAll(method.parameters
                  .where((p) => p.isRequiredPositional)
                  .map((parameter) => _toParameter(parameter)))
              ..optionalParameters = ListBuilder(
                method.parameters
                    .where((p) => !p.isRequiredPositional)
                    .map<Parameter>((parameter) => _toParameter(parameter)),
              )
              ..body = refer(_trackEventMethodName)
//              .property('track')
                  .call([
                literalString(_eventName(method.name)),
                _convertParametersToDictionary(method.parameters)
              ]).code
//            ..body = Code(
//                '''\n$_trackerFieldName.track('${method.name}', ${_convertParametersToDictionary(method.parameters)});\n'''),
            ));

    final c = Class((cb) {
      cb
        ..name = '_\$${element.name}'
        ..constructors.add(
          Constructor((conb) => conb
            ..optionalParameters.add(Parameter((pb) => pb
              ..name = _trackerFieldName
              ..type = _trackAnalyticsFunc.asNullable(true)))
            ..body = refer(_trackerFieldName)
                .notEqualTo(literalNull)
                .conditional(
                    _registerTrackerFunc.call([refer(_trackerFieldName)]),
                    literalNull)
                .statement),
        )
//        ..fields.add(Field((fb) => fb
//          ..name = _trackerFieldName
//          ..type = _trackAnalyticsFunc))
        ..extend = refer(element.name)
        ..mixins.add(refer('AnalyticsEventStubsImpl'))
        ..methods.addAll(methods);
    });

    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      useNullSafetySyntax: useNullSafetySyntax,
    );
    return '// useNullSafetySyntax: $useNullSafetySyntax\n' +
        DartFormatter().format('${c.accept(emitter)}');
//    return result.toString();
  }

  Expression _convertParametersToDictionary(List<ParameterElement> parameters) {
    final map = Map.fromEntries(parameters.map(
      (parameter) => MapEntry(
        literalString(parameter.name),
        _convertParameterValue(parameter),
      ),
    ));
    return literalMap(map, refer('String'), refer('dynamic'));
  }

  bool _isDartCore(DartType type) =>
      type.isDartCoreBool ||
      type.isDartCoreDouble ||
      type.isDartCoreInt ||
      type.isDartCoreString;

  String _eventName(String name) {
    for (final removeEventPrefix in _removeEventPrefix) {
      if (name.startsWith(removeEventPrefix)) {
        final eventName = name.substring(removeEventPrefix.length);
        return '${eventName[0].toLowerCase()}${eventName.substring(1)}';
      }
    }
    return name;
  }

  Expression _convertParameterValue(ParameterElement parameter) {
    final element = parameter.type.element;
    if (element is ClassElement) {
      if (element.isEnum) {
        if (element.nameLength > 0) {
          final isNullable =
              parameter.type.nullabilitySuffix != NullabilitySuffix.none;
          // Get rid of the enum name in the `toString`
          // ie. instead of `MyEnum.myValue` only use `myValue`
          return (isNullable
                  ? refer(parameter.name).nullSafeProperty('toString')
                  : refer(parameter.name).property('toString'))
              .call([])
              .property('substring')
              .call([literalNum(element.nameLength + 1)]);
        }
      }
    }
    return _isDartCore(parameter.type)
        ? refer(parameter.name)
        : refer(parameter.name).property('toString').call([]);
  }
}

extension on Reference {
  Reference asNullable(bool isNullable) {
    if (!isNullable) {
      return this;
    }
    return ((type as TypeReference).toBuilder()..isNullable = true).build();
  }
}
