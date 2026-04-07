import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:museai/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:museai/service_locator.dart';

import 'core/configs/themes/app_theme.dart';
import 'presentation/splash/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  await Supabase.initialize(
    url: 'https://fatxsbalyeebltrzzape.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhdHhzYmFseWVlYmx0cnp6YXBlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MTQzNzksImV4cCI6MjA5MTA5MDM3OX0.6c096JGo7Qlo9Rkx0jpuQrlyoLW189JOtWT389fDTT0',
  );

  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MuseAI',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
