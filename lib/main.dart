import 'DashBoard.dart';
import 'LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  bool shouldLogout = _shouldLogout(prefs);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.purple),
    home: (isLoggedIn && !shouldLogout) ? DashBoard() : Loginpage(prefs: prefs),
  ));
}

bool _shouldLogout(SharedPreferences prefs) {
  int loginTimestamp = prefs.getInt('loginTimestamp') ?? 0;
  int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
  int elapsedMilliseconds = currentTimestamp - loginTimestamp;
  int elapsedMinutes = elapsedMilliseconds ~/ (1000 * 60);
  return elapsedMinutes >= 1440;
}
