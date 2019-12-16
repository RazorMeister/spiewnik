import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'dart:developer';

import 'authors_page.dart';
import 'settings_page.dart';
import 'playlists_page.dart';
import 'details_page.dart';

import '../utils/main.dart';

import '../models/song_model.dart';
import '../models/settings_model.dart';


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

  bool _isLoadingFirst = false;
  bool _isData = false;
  bool _isText = false;
  List<Song> _allSongs = <Song>[];
  List<Song> _songs = <Song>[];
  List<Song> _recents = <Song>[];
  String _polishAlphabet = "aąbcćdeęfghijklłmnńoóprsśtuvwxyzźż0123456789";
  var _showCategories = Map();

  TextEditingController editingController = TextEditingController();

  _convertSongsString(String data) {
    int i = -1;
    int id;
    String category, title, text, chords, created;

    for (var string in data.split("@")) {
      if (i == -1) {
        i++;
      } else if (i == 0) {
        id = int.parse(string);
        i++;
      } else if (i == 1) {
        category = string;
        i++;
      } else if (i == 2) {
        title = string;
        i++;
      } else if (i == 3) {
        text = string;
        i++;
      } else if (i == 4) {
        chords = string;
        i++;
      } else {
        created = string;

        _showCategories[category] = true;

        Song song = Song(id, category, title, text, chords, created);
        _allSongs.add(song);
        i = 0;
      }
    }

    _allSongs.sort((a, b) {
      int aLower = _polishAlphabet.length, bLower = _polishAlphabet.length;
      int j = 0;

      do {
        for (int i=0; i<_polishAlphabet.length; i++) {
          if (_polishAlphabet[i] == a.title[j].toLowerCase())
            aLower = i;
          if (_polishAlphabet[i] == b.title[j].toLowerCase())
            bLower = i;
        }
        if (a.title.length == j+1 || b.title.length == j+1)
          break;

        j++;
      } while (aLower == bLower);


      return aLower.compareTo(bLower);
    });
  }

  _getSongs() async {
    bool reloaded = false;
    setState(() {
      _isLoadingFirst = true;
    });

    await http.get("http://malewand.vot.pl/spiewnikV2.php").then((response) { //http://malewand.vot.pl/spiewnikV2.php
      if (response.statusCode == 200) {
        String data = utf8.decode(response.bodyBytes);
        Utils.saveCache('songsString', 'String', data);
        _convertSongsString(data);
        setState(() {
          _isData = true;
          _songs.addAll(_allSongs);
        });
        reloaded = true;
      } else {
        Utils.getCache('songsString', 'String').then((data) {
          if (data == null) {
            data = '';
          }

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
          Utils.alertDuration(context);
        });
      }
    }).catchError((requestError) {
      log(requestError.toString());
      Utils.getCache('songsString', 'String').then((data) {
        if (data == null) {
          data = '';
        }

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
        Utils.alertDuration(context);
      });
    });

    setState(() {
      _isLoadingFirst = false;
    });

    return reloaded;
  }

  void _filterSearchResults(String query) {
    List<Song> dummySearchList = List<Song>();
    dummySearchList.addAll(_allSongs);
    if(query.isNotEmpty) {
      List<Song> dummyListData = List<Song>();
      dummySearchList.forEach((item) {
        if(item.title.toLowerCase().contains(query.toLowerCase()) || (settings.showCategory && item.category.toLowerCase().contains(query.toLowerCase()))) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _songs.clear();
        _songs.addAll(dummyListData);
      });
      return;
    } else {
      List<Song> dummyListData = List<Song>();
      dummySearchList.forEach((item) {
        if(_showCategories.containsKey(item.category) && _showCategories[item.category]) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _songs.clear();
        _songs.addAll(dummyListData);
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
    setState(() {
      _isData = false;
    });
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
      Utils.alertDuration(context);
    });
  }

  _addRecent(Song song) {
    List<Song> newRecents = <Song>[];

    newRecents.add(song);

    if (_recents.length > 0) {
      for (int i = 0; i < _recents.length && i < 5; i++) {
        if (_recents[i].title != song.title) {
          newRecents.add(_recents[i]);
        }
      }
    }

    _recents.clear();
    _recents.addAll(newRecents);
  }

  @override
  void initState() {
    _getSongs();
  }

  Widget checkboxCategory(String title, bool boolValue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(title),
        Checkbox(
          value: boolValue,
          onChanged: (bool value) {
            setState(() {
              _showCategories[title] = value;
              });
          },
        )
      ],
    );
  }

  Widget songTitle(List<Song> songs, int index) {
    if (settings.titleUpperCase) {
      return Text(songs[index].title.toUpperCase(), style: TextStyle(fontSize: settings.titleFontSize));
    } else {
      return Text(songs[index].title, style: TextStyle(fontSize: settings.titleFontSize));
    }
  }

  Widget songCategory(List<Song> songs, int index) {
    if (settings.showCategory) {
      return Text('Okres: ' + songs[index].category);
    } else {
      return null;
    }
  }

  Widget allSongs() {
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
              child: _songs.length == 0 ?
              Center(child: Text("Nie znaleziono takich piosenek.", style: TextStyle(fontSize: 20)))
                  :
              ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                      child: ListTile(
                          title: songTitle(_songs, index),
                          subtitle: songCategory(_songs, index),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          onTap: (){
                            _addRecent(_songs[index]);
                            Navigator.push(context,
                                new MaterialPageRoute(builder: (context) => DetailPage(_songs[index])));
                          },
                          onLongPress: () {

                          }
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

  Widget recentSongs() {
    return new Container(
      child: Scrollbar(
        child: _recents.length == 0 ?
        Center(
            child: Text("Brak ostatnich piosenek.")
        ) :
        ListView.builder(
          itemCount: _recents.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
                child: ListTile(
                  title: songTitle(_recents, index),
                  subtitle: songCategory(_recents, index),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  onTap: (){
                    Navigator.push(context,
                        new MaterialPageRoute(builder: (context) => DetailPage(_recents[index])));
                  },
                )
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: <Widget>[
                Visibility(
                  child: IconButton(
                    icon: Icon(Icons.autorenew),
                    onPressed: () {
                      _reloadSongs();
                    },
                  ),
                  visible: !_isLoadingFirst,
                ),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Informacje'),
                            content: Text('Ilość piosenek w bazie: ' + _allSongs.length.toString()),
                          );
                        }
                    );
                    Utils.alertDuration(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (_) {
                          return MyDialogContent(showCategories: _showCategories, refreshData: _filterSearchResults);
                        });
                  },
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Material(
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                            elevation: 20.0,
                            color: Colors.transparent,
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Image.asset('assets/spiewnik_icon.png', width: 100, height: 100)
                            ),
                          ),
                          Text(
                              'Menu',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3.0,
                                      color: Colors.black26,
                                      offset: Offset(2.0, 2.0),
                                    )
                                  ]
                              )
                          ),
                        ],
                      )
                    ),
                    decoration: BoxDecoration(
                      color: Utils.toMaterialColor(settings.primaryColor),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.playlist_play, size: 22),
                    title: Text('Playlisty', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          new MaterialPageRoute(builder: (context) => PlaylistsPage(_allSongs)));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, size: 22),
                    title: Text('Ustawienia', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          new MaterialPageRoute(builder: (context) => SettingsPage(setThemeData)));
                    },
                  ),
                  Divider(
                    color: Colors.grey,
                    indent: 12.0,
                    endIndent: 12.0,
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, size: 22),
                    title: Text('Informacje', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          new MaterialPageRoute(builder: (context) => AuthorsPage()));
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: TabBar(
                labelColor: Colors.black,
                labelStyle: TextStyle(fontSize: 20.0),
                indicatorColor: Colors.black,
                indicatorWeight: 4.0,
                indicatorPadding: EdgeInsets.all(2.0),
                tabs: [
                  Tab(text: 'Wszystkie'),
                  Tab(text: 'Ostatnie'),
                ],
              ),
            ),
            body: _isData ?
            TabBarView(
              children: [
                allSongs(),
                recentSongs(),
              ],
            )
                : (
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
        )
    );
  }
}

class MyDialogContent extends StatefulWidget {
  MyDialogContent({
    Key key,
    this.showCategories,
    this.refreshData,
  }): super(key: key);

  final showCategories;
  final Function refreshData;

  @override
  _MyDialogContentState createState() => new _MyDialogContentState(showCategories, refreshData);
}

class _MyDialogContentState extends State<MyDialogContent> {
  _MyDialogContentState(this.showCategories, this.refreshData);

  final showCategories;
  final Function refreshData;

  test() {
    List<Widget> categories = <Widget>[];

    showCategories.forEach((key, value) => {
      categories.add(
          new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(key),
              Checkbox(
                  value: showCategories[key],
                  onChanged: (bool newValue) {
                    setState(() {
                      showCategories[key] = newValue;
                    });
                  }
              ),
            ],
          )
        )
    });

    return categories;
  }

  @override
  void initState(){
    super.initState();
    test();
  }

  @override
  Widget build(BuildContext context) {
      return AlertDialog(
        title: Text('Filtrowanie'),
        content: Column(
          children: test(),
        ),
        actions: <Widget>[
          FlatButton(
            child: new Text("Zapisz"),
            onPressed: () {
              Navigator.of(context).pop();
              refreshData("");
            },
          ),
        ],
      );
  }
}