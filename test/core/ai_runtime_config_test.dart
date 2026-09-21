import 'dart:io';

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

  group('AIRuntimeConfig.load()', () {
    test('falls back to environment when file does not exist', () {
      final config = AIRuntimeConfig.load(
        envFilePath: 'non_existent_env_file.tmp',
      );
      expect(config.apiKey, AIRuntimeConfig.environment.apiKey);
      expect(config.useMock, AIRuntimeConfig.environment.useMock);
    });

    test('parses .env file and automatically activates real AI if key is present',
        () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/test_ai_runtime_${DateTime.now().millisecondsSinceEpoch}.env',
      );
      try {
        tempFile.writeAsStringSync('''
# Test comment
GEMINI_API_KEY="AIzaSyTestKey123"
GEMINI_MODEL=gemini-2.5-flash-test
AI_REQUEST_TIMEOUT_MS=15000
''');

        final config = AIRuntimeConfig.load(envFilePath: tempFile.path);
        expect(config.apiKey, 'AIzaSyTestKey123');
        expect(config.useMock, isFalse);
        expect(config.modelName, 'gemini-2.5-flash-test');
        expect(config.requestTimeoutMs, 15000);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });

    test('respects explicit USE_MOCK_AI=true even with key present', () {
      final tempFile = File(
        '${Directory.systemTemp.path}/test_ai_runtime_mock_${DateTime.now().millisecondsSinceEpoch}.env',
      );
      try {
        tempFile.writeAsStringSync('''
GEMINI_API_KEY=AIzaSyTestKey123
USE_MOCK_AI=true
''');

        final config = AIRuntimeConfig.load(envFilePath: tempFile.path);
        expect(config.apiKey, 'AIzaSyTestKey123');
        expect(config.useMock, isTrue);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });
  });
}

