library;

import 'package:analytics_event_gen/src/analytics_event_gen.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

export 'src/analytics_event_gen.dart';

Builder analyticsEventBuilder(BuilderOptions options) => SharedPartBuilder(
      [
        AnalyticsEventGenerator(
          useNullSafetySyntax:
              _toBoolean(options.config['useNullSafetySyntax']) ?? true,
        ),
      ],
      'analytics_event_builder',
    );

bool? _toBoolean(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  return null;
}
