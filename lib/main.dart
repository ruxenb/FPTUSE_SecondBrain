import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Contracts
import 'contracts/vault_service.dart';
import 'contracts/note_repository.dart';
import 'contracts/ai_service.dart';

// Mocks (Dùng cho Day 2-7)
import 'mocks/mock_vault_service.dart';
import 'mocks/mock_note_repository.dart';
import 'mocks/mock_ai_service.dart';

// Real Services (Tuần 2 sẽ bật khi thay thế mock)
import 'services/local_vault_service.dart';
import 'services/local_note_repository.dart';
import 'services/gemini_ai_service.dart';

// Providers
import 'providers/vault_provider.dart';
import 'providers/note_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/graph_provider.dart';

// Core & UI Shell
import 'core/theme/app_theme.dart';
import 'screens/shell_screen.dart';

/// CỜ ĐIỀU KHIỂN:
/// - Đặt `true`: Sử dụng Mock Services (chạy ngay lập tức với dữ liệu mẫu trong memory).
/// - Đặt `false`: Chuyển sang Real Services (đọc ghi ổ đĩa thật và gọi Gemini API).
const bool kUseMock = true;

/// Điền API Key Gemini của bạn tại đây khi chuyển kUseMock = false
const String kGeminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

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
        // 1. TẦNG CONTRACTS & SERVICES (Tùy biến theo cờ kUseMock)
        Provider<VaultService>(
          create: (_) => kUseMock ? MockVaultService() : LocalVaultService(),
        ),
        Provider<NoteRepository>(
          create: (_) => kUseMock ? MockNoteRepository() : LocalNoteRepository(),
        ),
        Provider<AIService>(
          create: (_) => kUseMock
              ? MockAIService()
              : GeminiAIService(apiKey: kGeminiApiKey),
        ),

        // 2. TẦNG BUSINESS LOGIC PROVIDERS
        ChangeNotifierProvider<VaultProvider>(
          create: (ctx) => VaultProvider(vaultService: ctx.read<VaultService>()),
        ),
        ChangeNotifierProvider<NoteProvider>(
          create: (ctx) => NoteProvider(noteRepository: ctx.read<NoteRepository>()),
        ),
        ChangeNotifierProvider<AIProvider>(
          create: (ctx) => AIProvider(aiService: ctx.read<AIService>()),
        ),
        ChangeNotifierProxyProvider<NoteProvider, GraphProvider>(
          create: (ctx) => GraphProvider(noteRepository: ctx.read<NoteRepository>()),
          update: (ctx, noteProvider, graphProvider) =>
              graphProvider!..updateFromNoteProvider(noteProvider),
        ),
      ],
      child: MaterialApp(
        title: 'FPTU SE Knowledge - Second Brain',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ShellScreen(),
      ),
    );
  }
}
