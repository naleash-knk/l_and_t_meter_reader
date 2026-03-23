import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:l_and_t_meter_reader/dashboard/dashboard.dart';
import 'package:l_and_t_meter_reader/home_screen/home_screen.dart';
import 'package:l_and_t_meter_reader/reports/report.dart';
import 'package:l_and_t_meter_reader/splash_screen/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:l_and_t_meter_reader/activity/activity_screen.dart';
import 'account_management/account_creation.dart';
import 'theme_vals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppCustomization(),
      child: Consumer<AppCustomization>(
        builder: (context, customization, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "FORMWORK UNIT-METALSHOP",
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: customization.themeMode,
            routes: {
              "/": (context) => const SplashScreen(),
              "/LoginScreen": (context) => const HomeScreen(),
              "/Dashboard": (context) => const DashboardScreen(),
              "/AccountCreation": (context) => const AccountCreationScreen(),
              "/Report": (context) => const ReportScreen(),
              "/Activity": (context) => const ActivityScreen(),
            },
          );
        },
      ),
    );
  }
}
