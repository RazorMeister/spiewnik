import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

final String VERSION = '1.0.2';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  loadSettings().then((x) {
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
      _primaryColor = toMaterialColor(settings.primaryColor);
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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.setThemeData}) : super(key: key);

  final String title;
  final Function setThemeData;

  @override
  _MyHomePageState createState() => _MyHomePageState(setThemeData);
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState(this.setThemeData);
  final Function setThemeData;
  bool _isData = false;
  bool _isText = false;
  List<Song> _allSongs = <Song>[];
  List<Song> _songs = <Song>[];

  TextEditingController editingController = TextEditingController();

  Future _saveSongsPrefs(String songsString) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString('songsString', songsString);
  }

  Future<String> _getSongsPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = '';
    try {
      data = prefs.getString('songsString') ?? '';
    } catch(error) {
      log('error w pobieraniu');
    }

    return data;
  }

  _convertSongsString(String data) {
    int i = -1;
    String title, text, chords;

    for (var string in data.split("@")) {
      if (i == -1) {
        i++;
      } else if (i == 0) {
        title = string;
        i++;
      } else if (i == 1) {
        text = string;
        i++;
      } else {
        chords = string;

        Song song = Song(title, text, chords);
        _allSongs.add(song);
        i = 0;
      }
    }

    _allSongs.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  _alertDuration() {
    const timeout = const Duration(seconds: 2);
    return new Timer(timeout, (() {
      Navigator.pop(context);
    }));
  }

  _getSongs() async {
    bool reloaded = false;

    await http.get("http://malewand.vot.pl/spiewnik.php").then((response) { //http://malewand.vot.pl/spiewnik.php
      if (response.statusCode == 200) {
        String data = utf8.decode(response.bodyBytes);
        _saveSongsPrefs(data);
        _convertSongsString(data);
        setState(() {
          _isData = true;
          _songs.addAll(_allSongs);
        });
        reloaded = true;
      } else {
        _getSongsPrefs().then((data) {
          _convertSongsString(data);
          setState(() {
            _isData = true;
            _songs.addAll(_allSongs);
          });
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Info'),
                  content: Text('Serwer nie odpowiada. Dane pobrane z cache.'),
                );
              }
          );
          _alertDuration();
        });
      }
    }).catchError((requestError) {
      _getSongsPrefs().then((data) {
        _convertSongsString(data);
        setState(() {
          _isData = true;
          _songs.addAll(_allSongs);
        });
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Info'),
                content: Text('Brak połączenia z internetem lub nieznany błąd!. Dane pobrane z cache.'),
              );
            }
        );
        _alertDuration();
      });
    });

    return reloaded;
  }

  void _filterSearchResults(String query) {
    List<Song> dummySearchList = List<Song>();
    dummySearchList.addAll(_allSongs);
    if(query.isNotEmpty) {
      List<Song> dummyListData = List<Song>();
      dummySearchList.forEach((item) {
        if(item.title.toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _songs.clear();
        _songs.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        _songs.clear();
        _songs.addAll(_allSongs);
      });
    }
  }

  _checkIsText() {
    setState(() {
      if (editingController.text == '') {
        _isText = false;
      } else {
        _isText = true;
      }
    });
  }

  _reloadSongs() {
    int count = _allSongs.length;
    _allSongs.clear();
    _songs.clear();
    _getSongs().then((reloaded) {
      if (count < _allSongs.length) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Info'),
                content: Text('Pobrano piosenki pomyślnie! Nowych piosenek: ' + (_allSongs.length - count).toString() + '.'),
              );
            }
        );
      } else {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Info'),
                content: Text('Pobrano piosenki pomyślnie!'),
              );
            }
        );
      }
      _alertDuration();
    });
  }


  @override
  void initState() {
    _getSongs();
  }

  Widget songTitle(List<Song> songs, int index) {
    if (settings.titleUpperCase) {
      return Text(songs[index].title.toUpperCase(), style: TextStyle(fontSize: settings.titleFontSize));
    } else {
      return Text(songs[index].title, style: TextStyle(fontSize: settings.titleFontSize));
    }
  }

  Widget MyUI() {
    return new Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _filterSearchResults(value);
                _checkIsText();
              },
              controller: editingController,
              decoration: InputDecoration(
                  hintText: "Szukaj",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(5.0))
                  ),
                  suffixIcon: Visibility(
                    visible: _isText,
                    child: InkWell(
                        onTap: () {
                          _filterSearchResults('');
                          editingController.clear();  // can cause an exception
                          _checkIsText();
                        },
                        child: SizedBox(
                            width: 30.0,
                            height: 30.0,
                            child: Stack(
                              alignment: Alignment(0.0, 0.0), // all centered
                              children: <Widget>[
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: Colors.grey[300]),
                                ),
                                Icon(
                                  Icons.clear,
                                  size: 30.0 * 0.6, // 60% width for icon
                                )
                              ],
                            )
                        )
                    ),
                  )
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                      child: ListTile(
                        title: songTitle(_songs, index),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        onTap: (){
                          Navigator.push(context,
                              new MaterialPageRoute(builder: (context) => DetailPage(_songs[index])));
                        },
                      )
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.autorenew),
              onPressed: () {
                _reloadSongs();
              },
            ),
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                Navigator.push(context,
                    new MaterialPageRoute(builder: (context) => AuthorsPage()));
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(context,
                    new MaterialPageRoute(builder: (context) => SettingsPage(setThemeData)));
              },
            )
          ],
        ),
        body: _isData ? MyUI() : (
            Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget> [
                      new CircularProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Ładowanie...',
                          style: TextStyle(color:  Theme.of(context).primaryColor),
                        ),
                      )
                    ]
                )
            )
        )
    );
  }
}

class DetailPage extends StatefulWidget {
  final Song song;
  DetailPage(this.song);

  @override
  _DetailPageState createState() => _DetailPageState(song);
}

class _DetailPageState extends State<DetailPage> {
  final Song song;
  _DetailPageState(this.song);

  bool _showChords = false;
  double _fontSize = settings.defaultFontSize;
  List<String> _currentChords = List<String>();
  List<String> _allChords = ["c", "cis", "d", "dis", "e", "f", "fis", "g", "gis", "a", "b", "h"];
  String _upperCases = "CDEFGABH";

  List<Widget> _getLines() {
    TextStyle defaultStyle = TextStyle(fontSize: _fontSize, color: Colors.black);
    bool isBold = false;
    List<Widget> childrenTexts = List<Widget>();

    int i = 0;

    for(var line in song.text.split("<br>")) {
      List<TextSpan> toAdd = List<TextSpan>();
      line = line.trim();

      if (_showChords && line != "") {
        toAdd.add(new TextSpan(text: "  |  "));
        if (i < _currentChords.length) {
          toAdd.add(new TextSpan(text: _currentChords[i].replaceAll('\n', ""), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)));
        }
      }

      if (line.contains("<b>")) {
        if (line.contains("</b>")) {
          isBold = false;
          line = line.replaceAll("</b>", "");
        } else {
          isBold = true;
        }
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line.replaceAll("<b>", ""),
            style: TextStyle(fontSize: _fontSize, color: Colors.black, fontWeight: FontWeight.bold),
            children: toAdd,
          ),
        ));
      } else if (line.contains("</b>")) {
        isBold = false;
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line.replaceAll("</b>", ""),
            style: TextStyle(fontSize: _fontSize, color: Colors.black, fontWeight: FontWeight.bold),
            children: toAdd,
          ),
        ));
      } else if (isBold){
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line,
            style: TextStyle(fontSize: _fontSize, color: Colors.black, fontWeight: FontWeight.bold),
            children: toAdd,
          ),
        ));
      } else {
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line,
            style: defaultStyle,
            children: toAdd,
          ),
        ));
      }
      i++;
    }
    return childrenTexts;
  }

  _changeChords(int type) {
    bool isDur = false;
    bool isSeven = false;

    List<String> newCurrentChords = List<String>();

    for (int i = 0; i < _currentChords.length; i++) {
      String currentChords = _currentChords[i];
      String newChordsLine = '';

      for (var currentChord in currentChords.split(' ')) {
        currentChord = currentChord.trim();
        String newChord = '';

        if (currentChord != '') {
          if (_upperCases.contains(currentChord[0])) {
            isDur = true;
          } else {
            isDur = false;
          }

          if (currentChord.length > 1 && currentChord.contains('7')) {
            isSeven = true;
            log(currentChord);
            //currentChord = currentChord.substring(0, currentChord.length-2);
          } else {
            isSeven = false;
          }

          currentChord = currentChord.toLowerCase();
          int index;
          bool isChord = false;

          for (int j = 0; j < _allChords.length; j++) {
            if (_allChords[j] == currentChord) {
              isChord = true;
              if (type == 1) {
                if (j == _allChords.length - 1) {
                  index = 0;
                } else {
                  index = j + 1;
                }
              } else {
                if (j == 0) {
                  index = _allChords.length - 1;
                } else {
                  index = j - 1;
                }
              }

              break;
            }
          }

          if (isChord) {
            newChord = _allChords[index];
            if (isSeven) {
              newChord += '7';
            }
            if (isDur) {
              newChord = newChord[0].toUpperCase() + newChord.substring(1, newChord.length);
            }
          } else if(currentChord != ' ') {
            newChord = currentChord;
          }
        }

        newChordsLine += newChord + ' ';
      }
      newCurrentChords.add(newChordsLine);
    }

    setState(() {
      _currentChords.clear();
      _currentChords.addAll(newCurrentChords);
    });
  }

  @override
  void initState() {
    super.initState();
    List<String> chords = song.chords.split("<br>");
    _currentChords.addAll(chords);
    _showChords = settings.showChords;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(song.title)
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(top: 20.0, bottom: 30.0),
          child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _getLines(),
              )
          ),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: (_showChords ? Theme.of(context).primaryColor : Colors.grey),
        child: const Icon(Icons.music_note), onPressed: () {
        setState(() {
          _showChords = !_showChords;
        });
      },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(icon: Icon(Icons.zoom_in), onPressed: () {
                  setState(() {
                    _fontSize += 2;
                  });
                }),
                IconButton(icon: Icon(Icons.zoom_out), onPressed: () {
                  setState(() {
                    _fontSize -= 2;
                  });
                }),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                  child: Text(
                    _fontSize.toInt().toString(),
                    textAlign: TextAlign.center,
                  ),
                ),

              ],
            ),
            Row(
              children: <Widget>[
                if (_showChords) IconButton(icon: Icon(Icons.arrow_upward), onPressed: () {
                  _changeChords(1);
                },
                ),
                if (_showChords) IconButton(icon: Icon(Icons.arrow_downward), onPressed: () {
                  _changeChords(0);
                },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

  _alertDuration() {
    const timeout = const Duration(seconds: 1);
    return new Timer(timeout, (() {
      Navigator.pop(context);
    }));
  }

  _submit() {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();
      saveSettings('defaultFontSize', 'double', _defaultFontSize);
      saveSettings('titleFontSize', 'double', _titleFontSize);
      saveSettings('showChords', 'bool', _showChords);
      saveSettings('primaryColor', 'int', _primaryColor.value);
      saveSettings('titleUpperCase', 'bool', _titleUpperCase);
      settings.defaultFontSize = _defaultFontSize;
      settings.titleFontSize = _titleFontSize;
      settings.showChords = _showChords;
      settings.primaryColor = _primaryColor.value;
      settings.titleUpperCase = _titleUpperCase;
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
      _alertDuration();
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

class AuthorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Autorzy')
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.only(left: 3.0, right: 3.0),
          child: SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text('Informacje o autorach', style: TextStyle(fontSize: 20.0)),
                    Divider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Kodowanie aplikacji:', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                        Text('Tymoteusz `RazorMeister` Bartnik'),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Baza piosenek:', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                        Text('ks. Maciej Lewandowski'),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Wersja: ' + VERSION, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                        Text('© Copyright 2019', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Song
{
  final String title;
  final String text;
  final String chords;

  Song(this.title, this.text, this.chords);
}

class Settings
{
  double defaultFontSize;
  bool showChords;
  int primaryColor;
  bool titleUpperCase;
  double titleFontSize;

  Settings(double _defaultFontSize, bool _showChords, int _primaryColor, bool _titleUpperCase, double _titleFontSize) {
    this.defaultFontSize = _defaultFontSize ?? 20.0;
    this.showChords = _showChords ?? false;
    this.primaryColor = _primaryColor ?? 4280391411;
    this.titleUpperCase = _titleUpperCase ?? false;
    this.titleFontSize = _titleFontSize ?? 24.0;
  }
}

Settings settings;

Future<bool> loadSettings() async{
  settings = new Settings(
    await getSettings('defaultFontSize', 'double'),
    await getSettings('showChords', 'bool'),
    await getSettings('primaryColor', 'int'),
    await getSettings('titleUpperCase', 'bool'),
    await getSettings('titleFontSize', 'double'),
  );

  return true;
}

Future<bool> saveSettings(String key, String type, value) async {
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
  }
}

Future<dynamic> getSettings(String key, String type) async {
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
  }
}

toMaterialColor(int colorValue) {
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
