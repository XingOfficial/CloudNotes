import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/storage_service.dart';
import 'services/local_data_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';
import 'screens/lock_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await LocalDataService.init();
  await NotificationService.init();
  themeModeNotifier.value = LocalDataService.isDarkMode() ? ThemeMode.dark : ThemeMode.light;
  runApp(const CloudNotesApp());
}

class CloudNotesApp extends StatelessWidget {
  const CloudNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasToken = StorageService.getToken() != null;
    final locked = hasToken && LocalDataService.hasPin();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: '云笔记',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh', 'CN'),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),
          themeMode: mode,
          home: !hasToken
              ? const LoginScreen()
              : locked
                  ? const LockScreen()
                  : const NotesListScreen(),
        );
      },
    );
  }
}
