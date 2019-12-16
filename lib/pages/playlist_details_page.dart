import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'dart:developer';

import '../utils/main.dart';

import '../models/song_model.dart';
import '../models/settings_model.dart';
import '../models/playlist_model.dart';

import 'playlist_add_songs_page.dart';
import 'details_page.dart';

class PlaylistDetailsPage extends StatefulWidget {
  PlaylistDetailsPage(this._playlist, this._allSongs, this._savePlaylists);

  final Playlist _playlist;
  final List<Song> _allSongs;
  final Function _savePlaylists;

  @override
  _PlaylistDetailsPageState createState() => _PlaylistDetailsPageState(_playlist, _allSongs, _savePlaylists);
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  _PlaylistDetailsPageState(this._playlist, this._allSongs, this._savePlaylists);

  final Playlist _playlist;
  final List<Song> _allSongs;
  final Function _savePlaylists;

  _deleteSong(int id) {
    for (int i = 0; i < _playlist.songs.length; i++) {
      if (_playlist.songs[i].id == id) {
        _playlist.songs.removeAt(i);
        break;
      }
    }

    setState(() {
      _savePlaylists();
    });
  }

  String _convertToString(Playlist playlist) {
    String playlistString = playlist.name + '@' + playlist.created.toString() + '@';
    for (Song song in playlist.songs) {
      playlistString += song.id.toString() + '@';
    }
    
    return playlistString;
  }


  @override
  void initState() {
    super.initState();
  }

  Widget deleteConfirmation(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Potwierdź usunięcie'),
            content: Text('Czy na pewno chcesz usunąć piosenkę: `' + _playlist.songs[index].title + '`?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Usuń'),
                onPressed: () {
                  _deleteSong(_playlist.songs[index].id);
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlista: ' + _playlist.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share('http://razormeister.pl/spiewnik/share.php?string=' + Uri.encodeFull(_convertToString(_playlist)));
            },
          ),
        ],
      ),
      body: _playlist.songs.length == 0 ?
      Center(
        child: Text('Brak piosenek!'),
      ) :
      Container(
        child: Scrollbar(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              Song toChange = _playlist.songs[oldIndex];
              List<Song> newSongs = <Song>[];
              int i = 0;

              for (Song song in _playlist.songs) {
                if (i == newIndex) {
                  newSongs.add(toChange);
                }
                if (song != toChange){
                  newSongs.add(song);
                }
                i++;
              }

              if (i == newIndex) {
                newSongs.add(toChange);
              }

              setState(() {
                _playlist.songs.clear();
                _playlist.songs.addAll(newSongs);
              });

              _savePlaylists();
            },
            children: <Widget>[
              for (int index = 0; index < _playlist.songs.length; index++)
                Card(
                  key: ValueKey(index),
                  child: ListTile(
                    trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteConfirmation(index),
                    ),
                    title: songTitle(_playlist.songs, index),
                    subtitle: songCategory(_playlist.songs, index),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    onTap: (){
                      Navigator.push(context,
                      new MaterialPageRoute(builder: (context) => DetailPage(_playlist.songs[index])));
                      },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              new MaterialPageRoute(builder: (context) => PlaylistAddSongsPage(_playlist, _allSongs, _savePlaylists)));
        },
        child: Icon(Icons.add),
        backgroundColor: Utils.toMaterialColor(settings.primaryColor),
      ),
    );
  }
}