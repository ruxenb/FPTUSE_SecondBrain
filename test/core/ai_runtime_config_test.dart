import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/core/constants/ai_runtime_config.dart';

void main() {
  test('valid AI runtime config passes validation', () {
    const config = AIRuntimeConfig(
      useMock: true,
      apiKey: '',
      modelName: 'model',
      requestTimeoutMs: 1000,
      maxRetryAttempts: 2,
      initialBackoffMs: 100,
      maxBackoffMs: 1000,
      retryJitterMs: 50,
      maxHistoryMessages: 8,
      clearStateOnNoteChange: true,
      mockDelayMs: 0,
    );

    expect(config.validate, returnsNormally);
  });

  test('invalid timeout is rejected', () {
    const config = AIRuntimeConfig(
      useMock: true,
      apiKey: '',
      modelName: 'model',
      requestTimeoutMs: 0,
      maxRetryAttempts: 2,
      initialBackoffMs: 100,
      maxBackoffMs: 1000,
      retryJitterMs: 50,
      maxHistoryMessages: 8,
      clearStateOnNoteChange: true,
      mockDelayMs: 0,
    );

    expect(config.validate, throwsStateError);
  });

  test('invalid history limit is rejected', () {
    const config = AIRuntimeConfig(
      useMock: true,
      apiKey: '',
      modelName: 'model',
      requestTimeoutMs: 1000,
      maxRetryAttempts: 2,
      initialBackoffMs: 100,
      maxBackoffMs: 1000,
      retryJitterMs: 50,
      maxHistoryMessages: 0,
      clearStateOnNoteChange: true,
      mockDelayMs: 0,
    );

    expect(config.validate, throwsStateError);
  });
}
