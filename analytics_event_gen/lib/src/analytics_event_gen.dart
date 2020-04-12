import 'dart:async';

import 'package:analytics_event_gen/src/annotation.dart';
import 'package:analyzer/dart/element/element.dart';
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
    final values = <String>{'// ignore_for_file: unnecessary_statements'};

    for (final element in library.allElements) {
      if (element is ClassElement && needsGenerate(element)) {
        final generatedValue = generateForElement(element, buildStep);
        for (final value in [generatedValue]) {
          assert(value == null || (value.length == value.trim().length));
          values.add(value);
        }
      }
    }
//    for (var annotatedElement in library.annotatedWith(typeChecker)) {
//      final generatedValue =
//          generateForAnnotatedElement(annotatedElement.element, annotatedElement.annotation, buildStep);
//      for (var value in [generatedValue]) {
//        assert(value == null || (value.length == value.trim().length));
//        values.add(value);
//      }
//    }

    return values.join('\n\n');
  }

  String generateForElement(Element element, BuildStep buildStep);

  bool needsGenerate(ClassElement classElement) {
    return typeChecker.isAssignableFrom(classElement);
  }
}

//class AnalyticsEventGenerator extends GeneratorForAnnotation<AnalyticsEventStubs> {
class AnalyticsEventGenerator
    extends GeneratorForImplementers<AnalyticsEventStubs> {
  static const _override = Reference('override');
  static const _trackerFieldName = 'tracker';

  /// internal method which forwards to [_trackerFieldName] if it is defined.
  static const _trackEventMethodName = 'trackEvent';
  static const _trackAnalyticsFunc = Reference('TrackAnalytics');
  static const _registerTrackerFunc = Reference('registerTracker');
  static const _removeEventPrefix = 'track';

  @override
  String generateForElement(Element element, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.name;
      throw InvalidGenerationSourceError('Generator cannot target `$name`.',
          todo: 'Remove the $AnalyticsEventStubs annotation from `$name`.',
          element: element);
    }
    final classElement = element as ClassElement;
    final result = StringBuffer();

    result.writeln('// got to generate for ${element.name}');

    final methods =
        classElement.methods.map((method) => Method.returnsVoid((mb) => mb
              ..name = method.name
              ..annotations.add(_override)
              ..optionalParameters = ListBuilder(
                (method.parameters.map<Parameter>((parameter) => Parameter(
                      (pb) => pb
                        ..name = parameter.name
                        ..type = refer(parameter.type.element.name)
                        ..named = true,
                    ))),
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
              ..type = _trackAnalyticsFunc))
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

    final emitter = DartEmitter(Allocator.simplePrefixing());
    return DartFormatter().format('${c.accept(emitter)}');
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
    if (name.startsWith(_removeEventPrefix)) {
      final eventName = name.substring(_removeEventPrefix.length);
      return '${eventName[0].toLowerCase()}${eventName.substring(1)}';
    }
    return name;
  }

  Expression _convertParameterValue(ParameterElement parameter) {
    final element = parameter.type?.element;
    if (element is ClassElement) {
      if (element.isEnum) {
        if (element.nameLength > 0) {
          // Get rid of the enum name in the `toString`
          // ie. instead of `MyEnum.myValue` only use `myValue`
          return refer(parameter.name)
              .nullSafeProperty('toString')
              .call([])
              .nullSafeProperty('substring')
              .call([literalNum(element.nameLength + 1)]);
        }
      }
    }
    return _isDartCore(parameter.type)
        ? refer(parameter.name)
        : refer(parameter.name).property('toString').call([]);
  }
}
