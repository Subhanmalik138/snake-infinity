import 'package:shared_preferences/shared_preferences.dart';

enum ControlMode { swipe, dpad, joystick }

class SaveData {
  int bestClassic = 0;
  int bestEndless = 0;
  int bestTimeAttack = 0;
  int unlockedLevel = 1;
  int totalGames = 0;
  int totalFoods = 0;
  int totalScore = 0;
  int longestSnake = 4;
  bool musicOn = true;
  bool sfxOn = true;
  bool vibrationOn = true;
  ControlMode control = ControlMode.swipe;
}

class StorageService {
  static Future<SaveData> load() async {
    final p = await SharedPreferences.getInstance();
    final d = SaveData();
    d.bestClassic = p.getInt('bestClassic') ?? 0;
    d.bestEndless = p.getInt('bestEndless') ?? 0;
    d.bestTimeAttack = p.getInt('bestTimeAttack') ?? 0;
    d.unlockedLevel = p.getInt('unlockedLevel') ?? 1;
    d.totalGames = p.getInt('totalGames') ?? 0;
    d.totalFoods = p.getInt('totalFoods') ?? 0;
    d.totalScore = p.getInt('totalScore') ?? 0;
    d.longestSnake = p.getInt('longestSnake') ?? 4;
    d.musicOn = p.getBool('musicOn') ?? true;
    d.sfxOn = p.getBool('sfxOn') ?? true;
    d.vibrationOn = p.getBool('vibrationOn') ?? true;
    final c = p.getString('control') ?? 'swipe';
    d.control = ControlMode.values.firstWhere(
      (e) => e.name == c,
      orElse: () => ControlMode.swipe,
    );
    return d;
  }

  static Future<void> save(SaveData d) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bestClassic', d.bestClassic);
    await p.setInt('bestEndless', d.bestEndless);
    await p.setInt('bestTimeAttack', d.bestTimeAttack);
    await p.setInt('unlockedLevel', d.unlockedLevel);
    await p.setInt('totalGames', d.totalGames);
    await p.setInt('totalFoods', d.totalFoods);
    await p.setInt('totalScore', d.totalScore);
    await p.setInt('longestSnake', d.longestSnake);
    await p.setBool('musicOn', d.musicOn);
    await p.setBool('sfxOn', d.sfxOn);
    await p.setBool('vibrationOn', d.vibrationOn);
    await p.setString('control', d.control.name);
  }
}
