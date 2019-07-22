import 'package:analytics_event_gen/src/annotation.dart';
import 'package:analyzer/dart/element/element.dart';
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
              .call([literalString(method.name), _convertParametersToDictionary(method.parameters)]).code
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
    final map = Map.fromEntries(
        parameters.map((parameter) => MapEntry(literalString(_eventName(parameter.name)), parameter.name)));
    return literalMap(map, refer('String'), refer('String'));
//    final result = StringBuffer('<String, dynamic>{');
//    for (final parameter in parameters) {
//      result..write('\'')..write(parameter.name)..write('\': ')..write(parameter.name);
//    }
//    result.write('}');
//    return result.toString();
  }

  String _eventName(String name) {
    if (name.startsWith(_removeEventPrefix)) {
      final eventName = name.substring(_removeEventPrefix.length);
      return '${eventName[0].toLowerCase()}${eventName.substring(1)}';
    }
    return name;
  }
}
