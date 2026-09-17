import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Contracts (Day 1 - Agreed by all 4 members)
import 'contracts/vault_service.dart';
import 'contracts/note_repository.dart';
import 'contracts/ai_service.dart';

// Mock AI hiện dùng cho đến khi Gemini được cấu hình.
import 'mocks/mock_vault_service.dart';
import 'mocks/mock_note_repository.dart';
import 'mocks/mock_ai_service.dart';
import 'services/local_vault_service.dart';
import 'services/local_note_repository.dart';

// Providers (Tầng State Management của 4 thành viên)
import 'providers/vault_provider.dart';
import 'providers/note_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/graph_provider.dart';

// Core & UI Shell
import 'core/theme/app_theme.dart';
import 'screens/shell_screen.dart';

/// Cờ giữ Mock cho các module chưa tích hợp dịch vụ thật.
const bool kUseMock = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FPTUSecondBrainApp());
}

class FPTUSecondBrainApp extends StatelessWidget {
  const FPTUSecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Contracts & Services
        Provider<VaultService>(
          create: (_) => kUseMock ? MockVaultService() : LocalVaultService(),
        ),
        Provider<NoteRepository>(
          create: (_) =>
              kUseMock ? MockNoteRepository() : LocalNoteRepository(),
        ),
        Provider<AIService>(
          create: (_) => kUseMock ? MockAIService() : MockAIService(), // TODO: Thay vế sau bằng GeminiAIService(apiKey: '...')
        ),

        // 2. Providers của 4 thành viên
        ChangeNotifierProvider<VaultProvider>(
          create: (ctx) =>
              VaultProvider(vaultService: ctx.read<VaultService>()),
        ),
        ChangeNotifierProvider<NoteProvider>(
          create: (ctx) =>
              NoteProvider(noteRepository: ctx.read<NoteRepository>()),
        ),
        ChangeNotifierProvider<AIProvider>(
          create: (ctx) => AIProvider(aiService: ctx.read<AIService>()),
        ),
        ChangeNotifierProxyProvider<NoteProvider, GraphProvider>(
          create: (ctx) =>
              GraphProvider(noteRepository: ctx.read<NoteRepository>()),
          update: (ctx, noteProvider, graphProvider) =>
              graphProvider!..updateFromNoteProvider(noteProvider),
        ),
      ],
      child: MaterialApp(
        title: 'FPTU SE Knowledge - Second Brain Template',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ShellScreen(),
      ),
    );
  }
}
