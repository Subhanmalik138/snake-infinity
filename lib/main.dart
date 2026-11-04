import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const SnakeInfinityApp());
}

class SnakeInfinityApp extends StatelessWidget {
  const SnakeInfinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Infinity: 3D Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1026),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF30D158)),
      ),
      home: const HomeScreen(),
    );
  }
}
