
class Song
{
  final int id;
  final String category;
  final String title;
  final String text;
  final String chords;
  final String created;

  Song(this.id, this.category, this.title, this.text, this.chords, this.created);

  String shorterTitle() {
    if (this.title.length > 15)
      return this.title.substring(0, 15) + '(...)';
    else
      return this.title;
  }
}