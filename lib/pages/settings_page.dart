import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:screen/screen.dart';

import '../utils/main.dart';

import '../models/settings_model.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(this.setThemeData);

  final Function setThemeData;

  @override
  _SettingsPageState createState() => _SettingsPageState(setThemeData);
}

class _SettingsPageState extends State<SettingsPage> {
  _SettingsPageState(this.setThemeData);

  final Function setThemeData;
  final formKey = GlobalKey<FormState>();
  double _defaultFontSize;
  double _titleFontSize;
  bool _showChords;
  bool _titleUpperCase;
  Color _primaryColor = Colors.red;
  bool _screenOn;
  bool _showCategory;


  _submit() {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();

      Utils.saveCache('defaultFontSize', 'double', _defaultFontSize);
      Utils.saveCache('titleFontSize', 'double', _titleFontSize);
      Utils.saveCache('showChords', 'bool', _showChords);
      Utils.saveCache('primaryColor', 'int', _primaryColor.value);
      Utils.saveCache('titleUpperCase', 'bool', _titleUpperCase);
      Utils.saveCache('screenOn', 'bool', _screenOn);
      Utils.saveCache('showCategory', 'bool', _showCategory);

      settings.defaultFontSize = _defaultFontSize;
      settings.titleFontSize = _titleFontSize;
      settings.showChords = _showChords;
      settings.primaryColor = _primaryColor.value;
      settings.titleUpperCase = _titleUpperCase;
      settings.screenOn = _screenOn;
      settings.showCategory = _showCategory;

      Screen.keepOn(_screenOn);

      setThemeData();

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sukces!'),
              content: Text('Zmiany zostały zapisane.'),
            );
          }
      );
      Utils.alertDuration(context);
    }
  }

  _openColorPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(6.0),
          title: Text('Wybierz kolor'),
          content: MaterialColorPicker(
            allowShades: false,
            selectedColor: _primaryColor,
            onMainColorChange: (color) => setState(() => _primaryColor = color),
            onBack: () => print("Back button pressed"),
          ),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _showChords = settings.showChords;
    _primaryColor = Color(settings.primaryColor);
    _titleUpperCase = settings.titleUpperCase;
    _screenOn = settings.screenOn;
    _showCategory = settings.showCategory;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Ustawienia')
      ),
      body: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: settings.defaultFontSize.toInt().toString(),
                    decoration: InputDecoration(
                      labelText: 'Domyślna wielkość czcionki (Domyślnie 20):',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (input) => (!(int.parse(input) is int) || (int.parse(input) > 60) || (int.parse(input) < 4)) ? 'Wprowadź liczbę od 4 do 60!' : null,
                    onSaved: (input) => _defaultFontSize = double.parse(input),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Pokazuj domyślnie akordy:'),
                      Checkbox(
                          value: _showChords,
                          onChanged: (bool value) {
                            setState(() {
                              _showChords = value;
                            });
                          }
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Wielkie litery w tytułach:'),
                      Checkbox(
                          value: _titleUpperCase,
                          onChanged: (bool value) {
                            setState(() {
                              _titleUpperCase = value;
                            });
                          }
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Pokazuj okres:'),
                      Checkbox(
                          value: _showCategory,
                          onChanged: (bool value) {
                            setState(() {
                              _showCategory = value;
                            });
                          }
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: settings.titleFontSize.toInt().toString(),
                    decoration: InputDecoration(
                      labelText: 'Wielkość czcionki tytułów (Domyślnie 24):',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (input) => (!(int.parse(input) is int) || (int.parse(input) > 60) || (int.parse(input) < 4)) ? 'Wprowadź liczbę od 4 do 60!' : null,
                    onSaved: (input) => _titleFontSize = double.parse(input),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Pozostaw ekran włączony:'),
                      Checkbox(
                          value: _screenOn,
                          onChanged: (bool value) {
                            setState(() {
                              _screenOn = value;
                            });
                          }
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Kolor aplikacji:'),
                      IconButton(
                        icon: Icon(Icons.color_lens),
                        onPressed: (){
                          _openColorPicker();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RaisedButton(
                        onPressed: _submit,
                        child: Text('Zapisz!'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}