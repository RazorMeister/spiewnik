import 'song_model.dart';

class Playlist
{
  String name;
  DateTime created;
  List<Song> songs;

  Playlist(this.name, this.created, this.songs);
}