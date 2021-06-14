import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progetto_flut/database/database.dart';
import 'package:progetto_flut/network/network.dart';

import 'displayCoin.dart';



class portfolio extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _portfolio();

}

class _portfolio extends State<portfolio>{
  //Lista che contiene le informazioni di ogni coin inserita
  var _coins = <Coin>[];
  //Lista che contiene i rispettivi saldi delle coin presi dal DB
  var _balances;
  //Variabile che indica quale bottone è cliccato tra "1h", "24h" e "7d" e mostra la relativa percentuale
  var _timeframe = 0;

  @override
  void initState() {
    super.initState();
    //Vengono inizializzati le variabili _coin e _balance rispettivamente da internet e da DB
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            height: 40,
            child: Align(
                alignment: Alignment.center,
                child: Text(
                    'Portfolio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )
                )
            )
        ),
        Container(
          child: Padding(
            padding: EdgeInsets.all(10),
            //Il saldo è calcolato in una funzione a parte
            child: _balances == null ? Text(
                "€0",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                )) : calculateTotalBalance(),
          ),
        ),
        Container(
          child: Padding(
            padding: EdgeInsets.all(10),
            //La percentuale è calcolata in una funzione a parte
            child: _balances == null ? Text("0%", style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            )) : calculateTotalPercentage(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: _timeframe == 0 ? null : () {setState(() {
                  _timeframe = 0;
                });
                },
                child: Text("1h")
            ),
            ElevatedButton(
                onPressed: _timeframe == 1 ? null : () {setState(() {
                  _timeframe = 1;
                });
                },
                child: Text("24h")
            ),
            ElevatedButton(
                onPressed: _timeframe == 2 ? null : () {setState(() {
                  _timeframe = 2;
                });
                },
                child: Text("7d")
            ),
          ],
        ),
        Container(child: Expanded(child: _buildCoins())),
      ],
    );
  }

  Widget _buildCoins() {
    //Nel caso balances è ancora null significa che l'app sta ancora scaricando da internet quindi viene mostrata l'animazione di caricamento
    if (_balances == null) {
      return Center(child: new CircularProgressIndicator());
    }
    //Se _balances non è null ma la sua lunghezza è 0, vuol dire che non ci sono transazioni
    if (_balances.length == 0){
      return Center(child: Text("Nessuna transazione"));
    }
    return ListView.builder(
        itemCount: _coins.length *2,
        padding: EdgeInsets.all(12.0),
        itemBuilder: /*1*/ (context, i) {

          if (i.isOdd) return Divider(); /*2*/

          final index = i ~/ 2; /*3*/

          //A _buildRow viene passata la moneta da visualizzare e il suo rispettivo saldo
          return _buildRow(_coins[index], _balances.firstWhere((v) => v.ticker == _coins[index].id));
        });
  }



  Widget _buildRow(Coin coin, Balance balance) {
    return ListTile(

      title: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: CachedNetworkImage(
              imageUrl: coin.imageUrl == null ? "" : coin.imageUrl!.replaceFirst("/large/", "/thumb/"),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(
            height: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    coin.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                        coin.price == null ? "und" : NumberFormat.currency(symbol: "€").format(double.tryParse(coin.price!) ?? (0)),
                        style: TextStyle(
                          fontSize: 13,
                        )
                    ),
                    Text(
                        "|",
                        style: TextStyle(
                          fontSize: 15,
                        )
                    ),
                    Text(
                        balance.balance == null ? "und" : NumberFormat.compact().format(balance.balance),
                        style: TextStyle(
                          fontSize: 13,
                        )
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(coin.price == null || balance == null ? "und" : NumberFormat.currency(symbol: "€").format((double.tryParse(coin.price!) ?? (0))*balance.balance)),
          Text(
              //Per calcolare le percentuali, viene usata una funzione definita sotto
              calculateSinglePercentage(coin) == null ? "und%" : NumberFormat.decimalPercentPattern(decimalDigits: 2).format(calculateSinglePercentage(coin)),
              style: TextStyle(
                fontSize: 15,
                color: (calculateSinglePercentage(coin) == null || calculateSinglePercentage(coin) == 0) ? Colors.black : (calculateSinglePercentage(coin)! > 0 ? Colors.green : Colors.red),
              )
          )
        ],
      ),
      onTap: () async {
        //Al click di una riga viene mostrati dettagli della relativa moneta.
        bool? refresh = await Navigator.push(
          this.context,
          MaterialPageRoute(builder: (context) {
            return displayCoin(coin);
          }),
        );
        //La pagina viene aggiornata ogni volta si torna indietro per visualizzare eventuali nuove transazioni.
        if (refresh == null){
          getData();
        }
      },
    );
  }

  //Funzione che si occupa di visualizzare il totale del saldo a schermo
  Widget calculateTotalBalance(){
    return Text(
        //Ogni saldo viene moltiplicato per il rispettibo prezzo e sommati insieme
        NumberFormat.currency(symbol: "€").format(_balances.fold(0.0, (p, c) {
          final price = _coins.firstWhere((element) => element.id == c.ticker);
          if (price.price == null) return p;
          print(c);
          return p + (c.balance*double.tryParse(price.price!) ?? (0));
        })),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 35,
        )
    );
  }

  //Funzione che si occupa di visualizzare la percentuale totale a schermo
  Widget calculateTotalPercentage(){
    return Text(
      //Ogni percentuale viene moltiplicata per il valore della moneta (saldo * prezzo) e poi divisa per il totale valore in modo da avere una media pesata
        NumberFormat.decimalPercentPattern(decimalDigits: 2).format(_balances.fold(0.0, (p, c) {
          Coin percentage = _coins.firstWhere((element) => element.id == c.ticker);
          if (percentage.price == null) return p;
          switch(_timeframe){
            case 0: {
              if (percentage.percentage1h == null) return p;
              return p + (c.balance*(double.tryParse(percentage.percentage1h!) ?? (0))*double.tryParse(percentage.price!) ?? (0));
            }
            case 1: {
              if (percentage.percentage24h == null) return p;
              return p + (c.balance*(double.tryParse(percentage.percentage24h!) ?? (0))*double.tryParse(percentage.price!) ?? (0));
            }
            case 2: {
              if (percentage.percentage7d == null) return p;
              return p + (c.balance*(double.tryParse(percentage.percentage7d!) ?? (0))*double.tryParse(percentage.price!) ?? (0));
            }
          }
          return p;

        }) / _balances.fold(0.0, (p,c) {
          final price = _coins.firstWhere((element) => element.id == c.ticker);
          if (price.price == null) return p;
          return p + ((c.balance * double.tryParse(price.price!) ?? (0)));
        })/100),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
        )
    );
  }

  //Funzione che calcola la singola percentuale in base al timefram scelto
  double? calculateSinglePercentage(Coin coin){
    switch(_timeframe){
      case 0:{
        if (coin.percentage1h == null) return null;
        return (double.tryParse(coin.percentage1h!) ?? (0))/100;
      }
      case 1:{
        if (coin.percentage24h == null) return null;
        return (double.tryParse(coin.percentage24h!) ?? (0))/100;
      }
      case 2:{
        if (coin.percentage7d == null) return null;
        return (double.tryParse(coin.percentage7d!) ?? (0))/100;
      }
      return null;
    }

  }

  //Funzione che si occupa di aggiornare lo stato da internet e database
  Future<Null> getData() async {
    final data = await getBalances();
    final coins = await getSpecificCoins(data.map((v) => v.ticker).toList());
    setState(() {
      _balances = data;
      _coins = coins;
    });
  }

}

