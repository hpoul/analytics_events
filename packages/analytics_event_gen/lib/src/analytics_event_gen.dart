import 'dart:async';

import 'package:analytics_event/analytics_event.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart' show Version;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

final _logger = Logger('analytics_event_gen');

abstract class GeneratorForImplementers extends Generator {
  TypeChecker get typeChecker;

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

    return '// ignore_for_file: unnecessary_statements\n\n${values.join('\n\n')}';
  }

  String generateForElement(Element element, BuildStep buildStep);

  bool needsGenerate(ClassElement classElement) {
    return typeChecker.isAssignableFrom(classElement);
  }
}

//class AnalyticsEventGenerator extends GeneratorForAnnotation<AnalyticsEventStubs> {
class AnalyticsEventGenerator extends GeneratorForImplementers {
  AnalyticsEventGenerator({required this.useNullSafetySyntax});

  @override
  TypeChecker get typeChecker =>
      const TypeChecker.typeNamed(AnalyticsEventStubs,
          inPackage: 'analytics_event');
  // TypeChecker get typeChecker => const TypeChecker.fromUrl(
  //     'package:analytics_event/analytics_event.dart#AnalyticsEventStubs');

  static const _analyticsEventConfigChecker =
      TypeChecker.typeNamed(AnalyticsEventConfig, inPackage: 'analytics_event');
  // static const _analyticsEventConfigChecker = TypeChecker.fromUrl(
  //     'package:analytics_event/analytics_event.dart#AnalyticsEventConfig');

  static const _override = Reference('override');
  static const _trackerFieldName = 'tracker';

  /// internal method which forwards to [_trackerFieldName] if it is defined.
  static const _trackEventMethodName = 'trackEvent';
  static const _trackAnalyticsFunc = Reference('TrackAnalytics');
  static const _registerTrackerFunc = Reference('registerTracker');
  static const _removeEventPrefix = ['_track', 'track'];

  bool useNullSafetySyntax;

  Parameter _toParameter(
    ClassElement classElement,
    FormalParameterElement parameter, {
    required Case nameCase,
  }) {
    final nullable =
        parameter.type.nullabilitySuffix == NullabilitySuffix.question;
    final isRequired = !nullable && parameter.defaultValueCode == null;
    if (parameter.isNamed && !parameter.isRequiredNamed && isRequired) {
      _logger.severe('named parameter is not nullable and has no default, '
          'but is not required. '
          '{$classElement}: {$parameter}');
    }
    return Parameter(
      (pb) => pb
        ..name = parameter.name ?? ''
        ..type = refer(parameter.type.element!.name!).asNullable(nullable)
        ..required =
            parameter.isNamed && (parameter.isRequiredNamed || isRequired)
        ..named = parameter.isNamed
        ..defaultTo = parameter.defaultValueCode == null
            ? null
            : Code(parameter.defaultValueCode!),
    );
  }

  T enumValueForDartObject<T>(
    DartObject source,
    List<T> items,
    String Function(T) name,
  ) =>
      items[source.getField('index')!.toIntValue()!];

  Case _getCaseFor(Element element, String fieldName) {
    final annotation = _analyticsEventConfigChecker.firstAnnotationOf(element,
        throwOnUnresolved: false);
    if (annotation != null) {
      final annotationReader = ConstantReader(annotation);
      return enumValueForDartObject(
        annotationReader.read('parameterNameCase').objectValue,
        Case.values,
        (f) => f.toString().split('.')[1],
      );
    }
    return Case.unchanged;
  }

  @override
  String generateForElement(Element element, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.displayName;
      throw InvalidGenerationSourceError('Generator cannot target `$name`.',
          todo: 'Remove the $AnalyticsEventStubs annotation from `$name`.',
          element: element);
    }
    final classElement = element;
    final result = StringBuffer();
    final eventNameCase = _getCaseFor(element, 'eventNameCase');
    final parameterNameCase = _getCaseFor(element, 'parameterNameCase');

    result.writeln('// got to generate for ${element.name}');

    final methods = classElement.methods
        .where((method) => method.isAbstract)
        .map((method) => Method.returnsVoid((mb) => mb
              ..name = method.name
              ..annotations.add(_override)
              ..requiredParameters.addAll(method.formalParameters
                  .where((p) => p.isRequiredPositional)
                  .map((parameter) => _toParameter(
                        classElement,
                        parameter,
                        nameCase: parameterNameCase,
                      )))
              ..optionalParameters = ListBuilder(
                method.formalParameters
                    .where((p) => !p.isRequiredPositional)
                    .map<Parameter>((parameter) => _toParameter(
                          classElement,
                          parameter,
                          nameCase: parameterNameCase,
                        )),
              )
              ..body = refer(_trackEventMethodName)
//              .property('track')
                  .call([
                literalString(
                    eventNameCase.convert(_eventName(method.name ?? ''))),
                _convertParametersToDictionary(
                  method.formalParameters,
                  nameCase: parameterNameCase,
                )
              ]).code
//            ..body = Code(
//                '''\n$_trackerFieldName.track('${method.name}', ${_convertParametersToDictionary(method.parameters)});\n'''),
            ));

    final c = Class((cb) {
      cb
        ..name = '_\$${element.displayName}'
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
        ..extend = refer(element.displayName)
        ..mixins.add(refer('AnalyticsEventStubsImpl'))
        ..methods.addAll(methods);
    });

    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      useNullSafetySyntax: useNullSafetySyntax,
    );
    return '// useNullSafetySyntax: $useNullSafetySyntax\n${DartFormatter(languageVersion: Version(3, 6, 0)).format('${c.accept(emitter)}')}';
//    return result.toString();
  }

  Expression _convertParametersToDictionary(
    List<FormalParameterElement> parameters, {
    required Case nameCase,
  }) {
    final map = Map.fromEntries(parameters.map(
      (parameter) => MapEntry(
        literalString(nameCase.convert(parameter.displayName)),
        _convertParameterValue(parameter),
      ),
    ));
    return literalMap(map, refer('String'), refer('Object').asNullable(true));
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

  Expression _convertParameterValue(FormalParameterElement parameter) {
    final element = parameter.type.element;
    if (element is ClassElement) {
      if (element is EnumElement) {
        if (element.displayName.isNotEmpty) {
          final isNullable =
              parameter.type.nullabilitySuffix != NullabilitySuffix.none;
          // Get rid of the enum name in the `toString`
          // ie. instead of `MyEnum.myValue` only use `myValue`
          return (isNullable
                  ? refer(parameter.displayName).nullSafeProperty('toString')
                  : refer(parameter.displayName).property('toString'))
              .call([])
              .property('substring')
              .call([literalNum(element.displayName.length + 1)]);
        }
      }
    }
    return _isDartCore(parameter.type)
        ? refer(parameter.displayName)
        : refer(parameter.displayName).property('toString').call([]);
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

extension on Case {
  String convert(String value) {
    switch (this) {
      case Case.unchanged:
        return value;
      case Case.camelCase:
        return value.camelCase;
      case Case.snakeCase:
        return value.snakeCase;
    }
  }
}
