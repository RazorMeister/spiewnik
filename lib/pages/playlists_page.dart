import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'dart:developer';

import '../utils/main.dart';

import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/settings_model.dart';

import 'playlist_details_page.dart';

class PlaylistsPage extends StatefulWidget {
  PlaylistsPage(this._allSongs);

  final List<Song> _allSongs;

  @override
  _PlaylistsPageState createState() => _PlaylistsPageState(_allSongs);
}

class _PlaylistsPageState extends State<PlaylistsPage> {

  _PlaylistsPageState(this._allSongs);

  final _addPlaylistKey = GlobalKey<FormState>();
  String _newPlaylistName;

  List<Playlist> _playlists = <Playlist>[];
  final List<Song> _allSongs;

  _getPlaylists() {
    Utils.getCache('playlists', 'list').then((playlistsList) {
      if (playlistsList != null) {
        _playlists.clear();
        for (int i=0; i < playlistsList.length; i++) {
          List<Song> songs = <Song>[];
          int k = 0;
          String playlistName;
          DateTime playlistCreated;

          for (var string in playlistsList[i].split("@")) {
            if (k == 0) {
              playlistName = string;
            } else if (k == 1) {
              playlistCreated = DateTime.parse(string);
            } else if (string != '' && string != ' '){
              for (Song song in _allSongs) {
                if (song.id == int.parse(string)) {
                  songs.add(song);
                  break;
                }
              }
            }
            k++;
          }

          Playlist newPlaylist = Playlist(playlistName, playlistCreated, songs);
          setState(() {
            _playlists.add(newPlaylist);
          });
        }
      }
    });
  }

  _savePlaylists() {
    List<String> toSave = <String>[];

    for (Playlist playlist in _playlists) {
      String playlistString = playlist.name + '@' + playlist.created.toString() + '@';
      for (Song song in playlist.songs) {
        playlistString += song.id.toString() + '@';
      }
      toSave.add(playlistString);
    }

    Utils.saveCache('playlists', 'list', toSave);
  }

  _savePlaylistString(String string) {
    List<String> toSave = <String>[];

    toSave.add(string);

    for (Playlist playlist in _playlists) {
      String playlistString = playlist.name + '@' + playlist.created.toString() + '@';
      for (Song song in playlist.songs) {
        playlistString += song.id.toString() + '@';
      }
      toSave.add(playlistString);
    }

    Utils.saveCache('playlists', 'list', toSave);
  }

   _addPlaylist(String playlistName) {
    List<Playlist> oldPlaylists = <Playlist>[];

    oldPlaylists.addAll(_playlists);

    Playlist newPlaylist = Playlist(playlistName, new DateTime.now(), <Song>[]);

    setState(() {
      _playlists.clear();
      _playlists.add(newPlaylist);
      _playlists.addAll(oldPlaylists);
    });

    _savePlaylists();
  }

  _editPlaylist(int index, String playlistName) {
      setState(() {
        _playlists[index].name = playlistName;
      });
      _savePlaylists();
  }

  _deletePlaylist(int index) {
    setState(() {
      _playlists.removeAt(index);
    });
    _savePlaylists();
  }

   _getSharedPlaylist(String url) async {
    await http.get(url).then((response) { //http://razormeister.pl/spiewnik/share.php?string=
      if (response.statusCode == 200) {
        String data = utf8.decode(response.bodyBytes);
        _savePlaylistString(data);
        _getPlaylists();
      } else {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Info'),
                content: Text('Serwer nie odpowiada!'),
              );
            }
        );
        Utils.alertDuration(context);
      }
    }).catchError((requestError) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Info'),
              content: Text('Brak połączenia z internetem lub nieznany błąd!'),
            );
          }
      );
      Utils.alertDuration(context);
    });
  }

  @override
  void initState() {
    super.initState();
    _getPlaylists();
  }

  Widget deleteConfirmation(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Potwierdź usunięcie'),
            content: Text('Czy na pewno chcesz usunąć playlistę: `' + _playlists[index].name + '`?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Usuń'),
                onPressed: () {
                  _deletePlaylist(index);
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Anuluj'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget editDialog(int index) {
    final _editPlaylistKey = GlobalKey<FormState>();
    String _playlistName;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Edytuj playlistę'),
                IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      Navigator.of(context).pop();
                      deleteConfirmation(index);
                    }
                ),
              ],
            ),
            content: Form(
              key: _editPlaylistKey,
              child: TextFormField(
                initialValue: _playlists[index].name,
                decoration: InputDecoration(
                  labelText: 'Nazwa playlisty',
                ),
                validator: (input) => (input.length < 3) ? 'Wprowadź conajmniej 3 znaki!' : null,
                onSaved: (input) => _playlistName = input,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Zapisz'),
                onPressed: () {
                  if (_editPlaylistKey.currentState.validate()) {
                    _editPlaylistKey.currentState.save();
                    _editPlaylist(index, _playlistName);
                    Navigator.of(context).pop();
                  }
                },
              ),
              FlatButton(
                child: Text('Anuluj'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Playlisty')
      ),
      body: _playlists.length == 0 ?
      Center(
        child: Text('Brak playlist!'),
      ) :
      Scrollbar(
        child: ListView.builder(
          itemCount: _playlists.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
                child: ListTile(
                  title: Text(_playlists[index].name, style: TextStyle(fontSize: 22)),
                  subtitle: _playlists[index].created != null ?
                  Text('Utworzone: ' + (new DateFormat("dd-MM-yyyy").format(_playlists[index].created)) + ' | Piosenek: ' + _playlists[index].songs.length.toString()) :
                  Text('Brak daty utworzenia'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      editDialog(index);
                    },
                  ),
                  onTap: (){
                    Navigator.push(context,
                        new MaterialPageRoute(builder: (context) => PlaylistDetailsPage(_playlists[index], _allSongs, _savePlaylists)));
                  },
                  onLongPress: () {
                    editDialog(index);
                  },
                )
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Dodaj nową playlistę'),
                  content: Form(
                    key: _addPlaylistKey,
                    child: TextFormField(
                      initialValue: '',
                      decoration: InputDecoration(
                        labelText: 'Nazwa playlisty',
                      ),
                      validator: (input) => (input.length < 3) ? 'Wprowadź conajmniej 3 znaki!' : null,
                      onSaved: (input) => _newPlaylistName = input,
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Dodaj z linka'),
                      onPressed: () {
                        if (_addPlaylistKey.currentState.validate()) {
                          _addPlaylistKey.currentState.save();
                          Navigator.of(context).pop();
                          _getSharedPlaylist(_newPlaylistName);
                        }
                      },
                    ),
                    FlatButton(
                      child: Text('Dodaj'),
                      onPressed: () {
                        if (_addPlaylistKey.currentState.validate()) {
                          _addPlaylistKey.currentState.save();
                          _addPlaylist(_newPlaylistName);
                          Navigator.of(context).pop();
                          Navigator.push(context,
                              new MaterialPageRoute(builder: (context) => PlaylistDetailsPage(_playlists[0], _allSongs, _savePlaylists)));
                        }
                      },
                    ),
                    FlatButton(
                      child: Text('Anuluj'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        },
        child: Icon(Icons.playlist_add),
        backgroundColor: Utils.toMaterialColor(settings.primaryColor),
      ),
    );
  }
}