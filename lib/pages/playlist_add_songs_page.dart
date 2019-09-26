import 'package:flutter/material.dart';
import 'dart:developer';

import '../utils/main.dart';

import '../models/song_model.dart';
import '../models/settings_model.dart';
import '../models/playlist_model.dart';

class PlaylistAddSongsPage extends StatefulWidget {
  PlaylistAddSongsPage(this._playlist, this._allSongs, this._savePlaylists);

  final Playlist _playlist;
  final List<Song> _allSongs;
  final Function _savePlaylists;

  @override
  _PlaylistAddSongsPageState createState() => _PlaylistAddSongsPageState(_playlist, _allSongs, _savePlaylists);
}

class _PlaylistAddSongsPageState extends State<PlaylistAddSongsPage> {
  _PlaylistAddSongsPageState(this._playlist, this._allSongs, this._savePlaylists);

  final Playlist _playlist;
  final List<Song> _allSongs;
  final Function _savePlaylists;
  List<Song> _songs = <Song>[];
  var _checked = new Map();

  TextEditingController editingController = TextEditingController();


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

  _manageSongs(int id, bool add) {
    if (add) {
      Song selectedSong;

      for (Song song in _allSongs) {
        if (song.id == id) {
          selectedSong = song;
          break;
        }
      }

      _playlist.songs.add(selectedSong);
    } else {
      for (int i = 0; i < _playlist.songs.length; i++) {
        if (_playlist.songs[i].id == id) {
          _playlist.songs.removeAt(i);
          break;
        }
      }
    }

    setState(() {
      _savePlaylists();
    });
  }

  @override
  void initState() {
    super.initState();
    _songs.addAll(_allSongs);

    for (Song song in _allSongs) {
      _checked[song.id] = false;

      for (Song playlistSong in _playlist.songs) {
        if (playlistSong.id == song.id) {
          _checked[song.id] = true;
          break;
        }
      }
    }
  }

  Widget songTitle(List<Song> songs, int index) {
    if (settings.titleUpperCase) {
      return Text(songs[index].title.toUpperCase(), style: TextStyle(fontSize: settings.titleFontSize));
    } else {
      return Text(songs[index].title, style: TextStyle(fontSize: settings.titleFontSize));
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Dodawanie piosenek')
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  _filterSearchResults(value);
                },
                controller: editingController,
                decoration: InputDecoration(
                    hintText: "Szukaj",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(5.0))
                    ),
                ),
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      color: _checked[_songs[index].id] ? Colors.green : Colors.white,
                        child: ListTile(
                            title: songTitle(_songs, index),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            trailing: _checked[_songs[index].id] ? Icon(Icons.check) : Icon(Icons.clear, color: Colors.red),
                            onTap: (){
                              setState(() {
                                _checked[_songs[index].id] = !_checked[_songs[index].id];
                              });
                              _manageSongs(_songs[index].id, _checked[_songs[index].id]);
                            },
                        )
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.check),
        backgroundColor: Utils.toMaterialColor(settings.primaryColor),
      ),
    );
  }
}