import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Utils
{
  static Future<bool> saveCache(String key, String type, value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch(type) {
      case 'String':
        return prefs.setString(key, value);
        break;
      case 'bool':
        return prefs.setBool(key, value);
        break;
      case 'int':
        return prefs.setInt(key, value);
        break;
      case 'double':
        return prefs.setDouble(key, value);
        break;
      case 'list':
        return prefs.setStringList(key, value);
        break;
    }
  }

  static Future<dynamic> getCache(String key, String type) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch(type) {
      case 'String':
        return prefs.getString(key);
        break;
      case 'bool':
        return prefs.getBool(key);
        break;
      case 'int':
        return prefs.getInt(key);
        break;
      case 'double':
        return  prefs.getDouble(key);
        break;
      case 'list':
        return prefs.getStringList(key);
        break;
    }
  }

  static toMaterialColor(int colorValue) {
    Map<int, Color> color =
    {
      50:Color.fromRGBO(136,14,79, .1),
      100:Color.fromRGBO(136,14,79, .2),
      200:Color.fromRGBO(136,14,79, .3),
      300:Color.fromRGBO(136,14,79, .4),
      400:Color.fromRGBO(136,14,79, .5),
      500:Color.fromRGBO(136,14,79, .6),
      600:Color.fromRGBO(136,14,79, .7),
      700:Color.fromRGBO(136,14,79, .8),
      800:Color.fromRGBO(136,14,79, .9),
      900:Color.fromRGBO(136,14,79, 1),
    };

    return MaterialColor(colorValue, color);
  }

  static alertDuration(BuildContext context) {
    const timeout = const Duration(seconds: 2);
    return new Timer(timeout, (() {
      Navigator.pop(context);
    }));
  }
}