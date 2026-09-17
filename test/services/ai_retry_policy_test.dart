import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fptu_se_second_brain/core/constants/ai_runtime_config.dart';
import 'package:fptu_se_second_brain/services/ai_retry_policy.dart';

const _config = AIRuntimeConfig(
  useMock: false,
  apiKey: 'test-key',
  modelName: 'test-model',
  requestTimeoutMs: 1000,
  maxRetryAttempts: 3,
  initialBackoffMs: 100,
  maxBackoffMs: 500,
  retryJitterMs: 50,
  maxHistoryMessages: 10,
  clearStateOnNoteChange: true,
  mockDelayMs: 0,
);

void main() {
  group('AIRetryPolicy', () {
    const policy = AIRetryPolicy(_config);

    test('retries transient timeout and rate-limit errors', () {
      expect(policy.shouldRetry(TimeoutException('timeout')), isTrue);
      expect(policy.shouldRetry(Exception('429 RESOURCE_EXHAUSTED')), isTrue);
      expect(policy.shouldRetry(Exception('503 UNAVAILABLE')), isTrue);
      expect(policy.shouldRetry(Exception('connection reset')), isTrue);
    });

    test('does not retry authentication and client configuration errors', () {
      expect(policy.shouldRetry(Exception('400 bad request')), isFalse);
      expect(policy.shouldRetry(Exception('401 unauthorized')), isFalse);
      expect(policy.shouldRetry(Exception('403 permission denied')), isFalse);
      expect(policy.shouldRetry(Exception('404 model_not_found')), isFalse);
    });

    test('classifies SDK ServerException by message before retrying', () {
      expect(
        policy.shouldRetry(ServerException('400 invalid argument')),
        isFalse,
      );
      expect(
        policy.shouldRetry(ServerException('403 permission denied')),
        isFalse,
      );
      expect(
        policy.shouldRetry(ServerException('503 service unavailable')),
        isTrue,
      );
      expect(
        policy.shouldRetry(ServerException('temporary backend failure')),
        isTrue,
      );
    });

    test('uses exponential backoff capped by configuration', () {
      expect(
        policy.delayForRetry(0, jitterMs: 0),
        const Duration(milliseconds: 100),
      );
      expect(
        policy.delayForRetry(1, jitterMs: 0),
        const Duration(milliseconds: 200),
      );
      expect(
        policy.delayForRetry(4, jitterMs: 0),
        const Duration(milliseconds: 500),
      );
    });

    test('caps jitter to configured maximum', () {
      expect(
        policy.delayForRetry(0, jitterMs: 999),
        const Duration(milliseconds: 150),
      );
    });
  });
}
