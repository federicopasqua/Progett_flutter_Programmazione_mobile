import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progetto_flut/network/network.dart';

import 'displayCoin.dart';



class search extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _search();

}

class _search extends State<search>{
  //Lista che contiene tutte le monete da mostrare a video
  var _displayedCoins = <Coin>[];
  //Lista contenente informazioni ridotte (nome e ticker) di TUTTE le monete
  var _coinsList = <Coin>[];
  //Lista che contiene le informazioni ridotte delle monete che rispettano i criteri di ricerca
  var _searchCoins;
  //Variabile che contiene la stringa cercata al momento
  var _currentQuery;

  //Variabile che contiene il timer il quale si attiva quando l'utente smette di scrivere e viene cancellato quando ricomincia
  var searchOnStoppedTyping;

  @override
  void initState() {
    super.initState();
    //Viene inizializzata la variabile _coinList
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(10.0),
          child: TextFormField(
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                icon: Icon(Icons.search)
            ),
            onChanged: (String? query) {
              //Se la query è ka stessa, non faccio niente
              if (_currentQuery != null && _currentQuery == query) return;
              //Aggiorno la variabile currentQuery e svuoto le liste contenenti le monete della ricerca precedente
              setState(() {
                _currentQuery = query;
                _displayedCoins = [];
                _searchCoins = null;
              });
              //Se la query è maggiore di 1 carattere (Limite aggiunto a causa di un limite delle API che non possono ricercare una quantità troppo grande di monete
              // simultaneamente)
              if (query != null && query.length > 1)
                setState(() {
                  //queryCoins viene popolata con le coin che rispettano i criteri di ricerca
                  final queryCoins = _coinsList.where((v) => v.symbol.toLowerCase().contains(query.toLowerCase()) || v.name.toLowerCase().contains(query.toLowerCase())).toList();
                  _searchCoins = queryCoins;

                  //Viene fatto partire il timer che, se non cencellato dall'utente (aggiungendo o eliminando caratteri), fa partire la funzione che aggiorna le
                  //monete visualizzate
                  const duration = Duration(milliseconds:800); // set the duration that you want call search() after that.
                  if (searchOnStoppedTyping != null) {
                    setState(() => searchOnStoppedTyping.cancel()); // clear timer
                  }
                  setState(() => searchOnStoppedTyping = new Timer(duration, () => refreshListCoins()));


                });
            },
          ),
        ),
        Container(child: Expanded(child: _buildCoins())),
      ],
    );
  }

  Widget _buildCoins() {

    if (_displayedCoins.length == 0 && (_searchCoins == null)){
      return Center(child: Text("Insert at least 2 characters to start"));
    }
    if (_searchCoins.length == 0){
      return Center(child: Text("Nothing found!"));
    }
    if (_displayedCoins.length == 0){
      return Center(child: new CircularProgressIndicator());
    }
    return ListView.builder(
        itemCount: _displayedCoins.length *2,
        padding: EdgeInsets.all(12.0),
        itemBuilder: /*1*/ (context, i) {

          if (i.isOdd) return Divider(); /*2*/

          final index = i ~/ 2; /*3*/


          return _buildRow(_displayedCoins[index]);
        });
  }



  Widget _buildRow(Coin coin) {
    return ListTile(

      title: Row(
        children: [
          Text(
            coin.marketCapRank == null ? "und" : coin.marketCapRank.toString(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: CachedNetworkImage(
              imageUrl: coin.imageUrl == null ? "" : coin.imageUrl!.replaceFirst("/large/", "/thumb/"),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          Flexible(
            child: Text(
              coin.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () {
        //Al click di una moneta, si visualizzano i dettagli
        Navigator.push(
          this.context,
          MaterialPageRoute(builder: (context) {
            return displayCoin(coin);
          }),
        );
      },
    );
  }

  //Funzione che si occupa di aggiornare le monete al cambio della query
  Future<Null> refreshListCoins() async {
    final queryList = _searchCoins.map((v) => v.id);
    final newData = await getSpecificCoins(queryList.take(450).toList());
    final List<Coin> data = List.from(_displayedCoins)..addAll(newData);

    data.sort((a,b) => a.compareTo(b));
    print(data.map((c) => c.name));
    setState(() {
      _displayedCoins = data;
    });

  }

  //Funzione che inizializza la variabile _coinList alla creazione del widget
  Future<Null> getData() async {
    final data = await getAllCoinsReduced();
    setState(() {
      _coinsList = data;
    });
  }

}
