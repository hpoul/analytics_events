import 'package:analytics_event_gen/src/annotation.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

class AnalyticsEventGenerator extends GeneratorForAnnotation<AnalyticsEvents> {
  static const _override = Reference('override');
  static const _trackerFieldName = 'tracker';
  static const _trackAnalyticsFunc = Reference('TrackAnalytics');
  static const _removeEventPrefix = 'track';

  @override
  dynamic generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.name;
      throw InvalidGenerationSourceError('Generator cannot target `$name`.',
          todo: 'Remove the $AnalyticsEvents annotation from `$name`.', element: element);
    }
    final classElement = element as ClassElement;
    final result = StringBuffer();

    result.writeln('// got to generate for ${element.name}');

    final methods = classElement.methods.map((method) => Method.returnsVoid((mb) => mb
          ..name = method.name
          ..annotations.add(_override)
          ..optionalParameters = ListBuilder(
            (method.parameters.map<Parameter>((parameter) => Parameter(
                  (pb) => pb
                    ..name = parameter.name
                    ..type = refer(parameter.type.name)
                    ..named = true,
                ))),
          )
          ..body = refer(_trackerFieldName)
//              .property('track')
              .call([literalString(_eventName(method.name)), _convertParametersToDictionary(method.parameters)]).code
//            ..body = Code(
//                '''\n$_trackerFieldName.track('${method.name}', ${_convertParametersToDictionary(method.parameters)});\n'''),
        ));

    final c = Class((cb) {
      cb
        ..name = '${element.name}Impl'
        ..constructors.add(
          Constructor((conb) => conb
            ..requiredParameters.add(Parameter((pb) => pb
              ..name = 'tracker'
              ..toThis = true))),
        )
        ..fields.add(Field((fb) => fb
          ..name = _trackerFieldName
          ..modifier = FieldModifier.final$
          ..type = _trackAnalyticsFunc))
        ..implements.add(refer(element.name))
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
      type.isDartCoreBool || type.isDartCoreDouble || type.isDartCoreInt || type.isDartCoreString;

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
    return _isDartCore(parameter.type) ? refer(parameter.name) : refer(parameter.name).property('toString').call([]);
  }
}
