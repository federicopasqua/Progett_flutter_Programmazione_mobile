import 'package:flutter/material.dart';

import 'package:progetto_flut/ui/market.dart';
import 'package:progetto_flut/ui/portfolio.dart';
import 'package:progetto_flut/ui/search.dart';




void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyApp();

}

class _MyApp extends State<MyApp> {

  int _currentIndex = 1;
  final tabs = [
    market(),
    portfolio(),
    search()
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
        body: SafeArea(child: tabs[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          iconSize: 30,
          selectedFontSize: 15,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: 'Markets'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Portfolio'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search'
            ),
          ],
          onTap: (index){
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      )
    );
  }
}











