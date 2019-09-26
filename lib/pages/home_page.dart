import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;

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

  bool _isData = false;
  bool _isText = false;
  List<Song> _allSongs = <Song>[];
  List<Song> _songs = <Song>[];
  List<Song> _recents = <Song>[];

  TextEditingController editingController = TextEditingController();

  _convertSongsString(String data) {
    int i = -1;
    int id = 0;
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

        Song song = Song(id++, title, text, chords);
        _allSongs.add(song);
        i = 0;
      }
    }

    _allSongs.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  _getSongs() async {
    bool reloaded = false;

    await http.get("http://malewand.vot.pl/spiewnik.php").then((response) { //http://malewand.vot.pl/spiewnik.php
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

  Widget songTitle(List<Song> songs, int index) {
    if (settings.titleUpperCase) {
      return Text(songs[index].title.toUpperCase(), style: TextStyle(fontSize: settings.titleFontSize));
    } else {
      return Text(songs[index].title, style: TextStyle(fontSize: settings.titleFontSize));
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
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                      child: ListTile(
                          title: songTitle(_songs, index),
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
                IconButton(
                  icon: Icon(Icons.autorenew),
                  onPressed: () {
                    _reloadSongs();
                  },
                ),
              ],
            ),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
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