import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/download_service.dart';
import 'data/repositories/app_repository.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/app_bloc.dart';
import 'presentation/bloc/download_bloc.dart';
import 'presentation/screens/splash_screen.dart';
import 'package:devstore/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = AuthService();
  final appRepository = AppRepository();
  final downloadService = DownloadService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: appRepository),
        RepositoryProvider.value(value: downloadService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authService)..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => AppBloc(context.read<AppRepository>()),
          ),
          BlocProvider(
            create: (context) => DownloadBloc(
              context.read<DownloadService>(),
              context.read<AppRepository>(),
            ),
          ),
        ],
        child: const DevStoreApp(),
      ),
    ),
  );
}

class DevStoreApp extends StatelessWidget {
  const DevStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Aᴘᴘ Sᴛᴏʀᴇ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
              Locale('es'),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
