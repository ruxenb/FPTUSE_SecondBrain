import 'dart:async';
import 'dart:math' as math;

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/ai_runtime_config.dart';

class AIRetryPolicy {
  const AIRetryPolicy(this.config);

  final AIRuntimeConfig config;

  bool shouldRetry(Object error) {
    if (error is InvalidApiKey ||
        error is UnsupportedUserLocation ||
        error is GenerativeAISdkException) {
      return false;
    }
    if (error is TimeoutException) {
      return true;
    }

    final message = error.toString().toLowerCase();

    if (_containsAny(message, const [
      '400',
      '401',
      '403',
      '404',
      'invalid api key',
      'permission denied',
      'permission_denied',
      'model_not_found',
      'model not found',
      'invalid argument',
      'bad request',
      'failed precondition',
      'unauthorized',
      'not found',
    ])) {
      return false;
    }

    if (error is ServerException) {
      return true;
    }

    return _containsAny(message, const [
      '408',
      '429',
      '500',
      '502',
      '503',
      '504',
      'resource_exhausted',
      'rate limit',
      'unavailable',
      'deadline_exceeded',
      'timeout',
      'timed out',
      'socket',
      'connection reset',
      'connection closed',
      'network',
    ]);
  }

  Duration delayForRetry(int retryIndex, {int jitterMs = 0}) {
    if (retryIndex < 0) {
      throw ArgumentError.value(retryIndex, 'retryIndex');
    }

    final exponential =
        config.initialBackoffMs * math.pow(2, retryIndex).toInt();
    final capped = math.min(exponential, config.maxBackoffMs);
    final safeJitter = jitterMs.clamp(0, config.retryJitterMs).toInt();

    return Duration(milliseconds: capped + safeJitter);
  }

  bool _containsAny(String value, List<String> patterns) {
    return patterns.any(value.contains);
  }
}
