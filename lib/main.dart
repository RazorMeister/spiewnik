import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'dart:async';

import 'utils/main.dart';

import 'models/settings_model.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  loadSettings().then((x) {
    Screen.keepOn(settings.screenOn);
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MaterialColor _primaryColor;

  _setPrimaryColor() {
    setState(() {
      _primaryColor = Utils.toMaterialColor(settings.primaryColor);
    });
  }

  @override
  void initState() {
      super.initState();
      _setPrimaryColor();
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Śpiewnik',
      theme: ThemeData(
        primarySwatch: _primaryColor,
        accentColor: Colors.grey,
        cursorColor: Colors.grey,
        textSelectionColor: Colors.grey,
        textSelectionHandleColor: Colors.grey,
      ),
      home: MyHomePage(title: 'Śpiewnik', setThemeData: _setPrimaryColor),
    );
  }
}


Future<bool> loadSettings() async{
  settings = new Settings(
    await Utils.getCache('defaultFontSize', 'double'),
    await Utils.getCache('showChords', 'bool'),
    await Utils.getCache('primaryColor', 'int'),
    await Utils.getCache('titleUpperCase', 'bool'),
    await Utils.getCache('titleFontSize', 'double'),
    await Utils.getCache('screenOn', 'bool'),
  );

  return true;
}