import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'services/recommendation_service.dart';
import 'services/location_service.dart';

void main() {
  runApp(const UniversalStudiosApp());
}

class UniversalStudiosApp extends StatelessWidget {
  const UniversalStudiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecommendationService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
      ],
      child: MaterialApp(
        title: 'Universal Studios Orlando',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF1976D2),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
} 