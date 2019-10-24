import 'package:flutter/material.dart';

import '../models/song_model.dart';
import '../models/settings_model.dart';

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
  List<String> _allChords = [
    "c",
    "cis",
    "d",
    "dis",
    "e",
    "f",
    "fis",
    "g",
    "gis",
    "a",
    "b",
    "h"
  ];
  String _upperCases = "CDEFGABH";

  List<Widget> _getLines() {
    TextStyle defaultStyle = TextStyle(
        fontSize: _fontSize, color: Colors.black);
    bool isBold = false;
    List<Widget> childrenTexts = List<Widget>();

    int i = 0;

    for (var line in song.text.split("<br>")) {
      List<TextSpan> toAdd = List<TextSpan>();
      line = line.trim();

      if (_showChords && line != "") {
        toAdd.add(new TextSpan(text: "  |  "));
        if (i < _currentChords.length) {
          toAdd.add(new TextSpan(text: _currentChords[i].replaceAll('\n', ""),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red)));
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
            style: TextStyle(fontSize: _fontSize,
                color: Colors.black,
                fontWeight: FontWeight.bold),
            children: toAdd,
          ),
        ));
      } else if (line.contains("</b>")) {
        isBold = false;
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line.replaceAll("</b>", ""),
            style: TextStyle(fontSize: _fontSize,
                color: Colors.black,
                fontWeight: FontWeight.bold),
            children: toAdd,
          ),
        ));
      } else if (isBold) {
        childrenTexts.add(RichText(
          text: TextSpan(
            text: line,
            style: TextStyle(fontSize: _fontSize,
                color: Colors.black,
                fontWeight: FontWeight.bold),
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

    List<String> newCurrentChords = List<String>();

    for (int i = 0; i < _currentChords.length; i++) {
      String currentChords = _currentChords[i];
      String newChordsLine = '';

      for (var currentChord in currentChords.split(' ')) {
        currentChord = currentChord.trim();
        String newChord = '';
        String prefix = "", sufix = "";
        bool isSeven = false;

        if (currentChord != '') {
          if (currentChord.length > 1) {
            if (currentChord[0] == '(') {
              prefix = "(";
              currentChord = currentChord.substring(1, currentChord.length);
            }
            if (currentChord[currentChord.length-1] == ')') {
              sufix = ")";
              currentChord = currentChord.substring(0, currentChord.length-1);
            }
            if (currentChord.contains('7')) {
              isSeven = true;
              currentChord = currentChord.substring(0, currentChord.length-1);
            }
          }

          if (_upperCases.contains(currentChord[0])) {
            isDur = true;
          } else {
            isDur = false;
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
            if (prefix != "") {
              newChord = prefix + newChord;
            }

            if (sufix != "") {
              newChord += sufix;
            }

            if (isSeven) {
              newChord += '7';
            }
            if (isDur) {
              newChord = newChord[0].toUpperCase() +
                  newChord.substring(1, newChord.length);
            }
          } else if (currentChord != ' ') {
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
          width: MediaQuery
              .of(context)
              .size
              .width,
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
        backgroundColor: (_showChords ? Theme
            .of(context)
            .primaryColor : Colors.grey),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 2.0),
                  child: Text(
                    _fontSize.toInt().toString(),
                    textAlign: TextAlign.center,
                  ),
                ),

              ],
            ),
            Row(
              children: <Widget>[
                if (_showChords) IconButton(
                  icon: Icon(Icons.arrow_upward), onPressed: () {
                  _changeChords(1);
                },
                ),
                if (_showChords) IconButton(
                  icon: Icon(Icons.arrow_downward), onPressed: () {
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