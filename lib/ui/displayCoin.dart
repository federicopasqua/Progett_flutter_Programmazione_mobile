import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progetto_flut/database/database.dart';
import 'package:progetto_flut/network/network.dart';

import 'insertCoin.dart';


class displayCoin extends StatefulWidget{

  final Coin coin;
  displayCoin(this.coin);

  @override
  State<StatefulWidget> createState() => _displayCoin();
}

class _displayCoin extends State<displayCoin>{

  //Variabile che contiene tutte le transazioni eseguite sulla specifica moneta
  var _transactions;
  //Variabile che contiene tutte le della moneta e che viene passata dal widget che chiama questo
  var _coin;
  //Variabile che contiene il saldo dell moneta
  var _balance;
  //Variabile booleana per indicare se ci troviamo nella tab dettagli o transazioni
  var _toggle = false;
  //Variabile che indica quando tutte le infromazioni sono state scaricate
  var _loaded = false;

  //Vettore utilizzato per convertire i tipi di transazioni da intero (salvati ne DB) a stringa
  final states = ["BUY", "SELL", "IN", "OUT", "MINING", "STACKING"];

  @override
  void initState() {
    super.initState();
    //Viene inizializzata le informazioni delle coin prendendole dal widget da cui si proviene
    _coin = widget.coin;
    //Viene aggiornato saldo e transazioni
    getData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.only(bottom: 25)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: _coin.imageUrl == null ? "" : _coin.imageUrl!.replaceFirst("/large/", "/thumb/"),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                Text(
                    _coin.name == null ? "unknown" : _coin.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )
                )
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 25)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    (_balance != null && _loaded) ? NumberFormat.currency(name: _coin.symbol.toUpperCase()).format(_balance) : NumberFormat.currency(name: _coin.symbol.toUpperCase()).format(0),
                    style: TextStyle(
                      fontSize: 20,
                    )
                ),
                Padding(padding: EdgeInsets.only(right: 15, left: 15)),
                Text(
                    (_balance != null && _coin.price != null && _loaded) ? NumberFormat.currency(symbol: "€").format((double.tryParse(_coin.price) ?? (0))*_balance): "€0",
                    style: TextStyle(
                      fontSize: 20,
                    )
                )
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 25)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Alla pressione dei tasti, viene invertita la variabile toggle e quindi cambiata la tab da visualizzare
                ElevatedButton(
                    onPressed: _toggle ? () {setState(() {_toggle = !_toggle;});} : null,
                    child: Text("Details")
                ),
                ElevatedButton(
                    onPressed: !_toggle ? () {setState(() {_toggle = !_toggle;});} : null,
                    child: Text("Transactions")
                )
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 25)),
            Container(child: Expanded(child: _buildBottomPart())),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        //FAB mostrato solo nella tab transazioni
        visible: _toggle,
        child: FloatingActionButton(

          backgroundColor: const Color(0xff03dac6),
          foregroundColor: Colors.black,
          onPressed: () async {
            bool? refresh = await Navigator.push(
              this.context,
              MaterialPageRoute(builder: (context) {
                return insertCoin(_coin);
              }),
            );
            //Lo stato viene aggiornato solo nel caso sia stata aggionta una nuova transazione
            if (refresh != null && refresh){
              getData();
            }
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBottomPart() {
    if ((_coin ==  null && !_toggle) || (!_loaded && _toggle)){
      return Center(child: new CircularProgressIndicator());
    }
    if (_toggle && _loaded && _transactions.length == 0){
      return Text("No Transactions found");
    }
    //Se ci troviamo nella tab transazioni
    if (_toggle){
      return ListView.builder(
          itemCount: _transactions.length*2,
          padding: EdgeInsets.all(12.0),
          itemBuilder: /*1*/ (context, i) {

            if (i.isOdd) return Divider(); /*2*/

            final index = i ~/ 2;
            return _buildTrasanctionRow(_transactions[index]);
          });
    }else{
      //se ci troviamo nella tab dettagli
      return ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _coin.price == null ? "€und" : NumberFormat.currency(symbol: "€").format(double.tryParse(_coin.price) ?? (0)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )
                ),
                Text(
                    _coin.percentage24h == null ? "und%" : NumberFormat.decimalPercentPattern(decimalDigits: 2).format((double.tryParse(_coin.percentage24h) ?? (0))/100),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Rank",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15 ,
                        )
                    ),
                    Text(
                        _coin.marketCapRank == null ? "und" : _coin.marketCapRank.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Marketcap",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )
                    ),
                    Text(
                        _coin.marketCap == null ? "und" : NumberFormat.compactCurrency(symbol: "€").format(double.tryParse(_coin.marketCap) ?? (0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Volume",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )
                    ),
                    Text(
                        _coin.volume == null ? "und" : NumberFormat.compactCurrency(symbol: "€").format(double.tryParse(_coin.volume) ?? (0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Supply",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )
                    ),
                    Text(
                        _coin.supply == null ? "und" : NumberFormat.compactLong().format(double.tryParse(_coin.supply) ?? (0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                )
              ],
            ) ,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "High (24h)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )
                    ),
                    Text(
                        _coin.high == null ? "und" : NumberFormat.currency(symbol: "€").format(double.tryParse(_coin.high) ?? (0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Low (24h)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )
                    ),
                    Text(
                        _coin.low == null ? "und" : NumberFormat.currency(symbol: "€").format(double.tryParse(_coin.low) ?? (0)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )
                    )
                  ],
                )
              ],
            ),
          )
        ],
      );
    }

  }



  Widget _buildTrasanctionRow(Transaction trans) {
    return ListTile(

        title: Row(
          children: [
            Text(
                states[trans.type],
                style: TextStyle(
                  fontSize: 20,
                )
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20)),
            Text(
                NumberFormat.decimalPattern().format(trans.amount.abs())  + " " + _coin.symbol.toUpperCase()
            ),
          ],
        ),
        trailing: IconButton(
            onPressed: (){
              //Eliminazione della transazione e aggiornamento dello stato
              deleteTransactionById(trans.id);
              getData();
            },
            icon: Icon( Icons.delete)
        )

    );
  }

  //Funzione ch aggiorna saldo e lista delle transazioni
  Future<Null> getData() async {
    final balance_list = await getCoinBalance(_coin.id);
    double balance = 0;
    for (final balance_i in balance_list){
      if (balance_i.ticker == _coin.id){
        balance = balance_i.balance;
        break;
      }
    }
    final transactions = await getTransactionsByTicker(_coin.id);
    setState(() {
      _balance = balance;
      _transactions = transactions;
      _loaded = true;
    });
  }


}