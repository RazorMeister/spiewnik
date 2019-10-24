import 'package:flutter/material.dart';
import 'package:share/share.dart';

final String VERSION = '1.0.4';

class AuthorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Autorzy'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share('Śpiewnik wykonany przez Tymoteusz `RazorMeister` Bartnik. Zobacz więcej na http://razormeister.pl');
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.only(left: 3.0, right: 3.0),
          child: SizedBox(
            height: 250,
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
                        Text('&'),
                        Text('Stanisław Wołowski'),
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