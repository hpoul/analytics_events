library analytics_event_gen_builder;

import 'package:analytics_event_gen/src/analytics_event_gen.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

export 'src/analytics_event_gen.dart';

Builder analyticsEventBuilder(BuilderOptions options) => SharedPartBuilder(
      [
        AnalyticsEventGenerator(),
      ],
      'analytics_event_builder',
    );
