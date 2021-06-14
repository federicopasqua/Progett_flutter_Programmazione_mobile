import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progetto_flut/network/network.dart';
import 'package:cached_network_image/cached_network_image.dart';


import 'displayCoin.dart';


class market extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _market();

}

class _market extends State<market> {
  //Liasta che contiene tutte le monete da visualizzare
  var _coins = <Coin>[];
  //variabile che contiene l'ultima pagina che è stata aggiornata
  var _page = 1;
  //Variabile che indica se si è entrati nel processo di aggiunta di nuove coin alla fine
  var _loading = false;

  @override
  void initState() {
    super.initState();
    //Viene scaricata la prima pagina dalle api per essere visualizzata
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            height: 40 ,
            child: Align(alignment: Alignment.center,
                child: Text(
                    'Market',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )
                )
            )
        ),
        Padding(padding: EdgeInsets.all(10)),
        Container(child: Expanded(child: _buildCoins())),
      ],
    );
  }

  Widget _buildCoins() {
    //Se l'array di coins è vuoto, l'app sta ancora facendo il download delle informazioni e quindi mostro l'animazione di caricamento
    if (_coins.length == 0){
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _coins.length *2,
        padding: EdgeInsets.all(12.0),
        itemBuilder: /*1*/ (context, i) {

          if (i.isOdd) return Divider(); /*2*/

          final index = i ~/ 2; /*3*/

          //Quando l'utente arriva a 20 item dalla fine, inizia il download della pagina sequente
          if (index >= _coins.length - 20 && _loading == false) {
            _loading = true;
            _page++;
            refreshListCoins(_page);
          }
          return _buildRow(_coins[index]);
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
                Text(
                    coin.marketCap == null ? "und" : NumberFormat.compactCurrency(symbol: "€").format(double.tryParse(coin.marketCap!) ?? (0)),
                    style: TextStyle(
                      fontSize: 15,
                    )
                )
              ],
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(coin.price == null ? "und" : NumberFormat.currency(symbol: "€").format(double.tryParse(coin.price!) ?? (0))),
          Text(
              coin.percentage24h == null ? "und%" : NumberFormat.decimalPercentPattern(decimalDigits: 2).format((double.tryParse(coin.percentage24h!) ?? (0))/100),
              style: TextStyle(
                fontSize: 15,
                //Colorazione condizionale in base al segno
                color: (coin.percentage24h == null || (double.tryParse(coin.percentage24h!) ?? (0)) == 0) ? Colors.black : (coin.percentage24h != null && (double.tryParse(coin.percentage24h!) ?? (0)) > 0 ? Colors.green : Colors.red),
              )
          )
        ],
      ),
      onTap: () {
        //Al click su una riga, si va alla pagina di visualizzazione dettagli
        Navigator.push(
          this.context,
          MaterialPageRoute(builder: (context) {
            return displayCoin(coin);
          }),
        );
      },
    );
  }

  //Funzione che si occupa di aggiungere una nuova pagina alla lista Coin
  Future<Null> refreshListCoins(int page) async {
    try{
      final new_data = await getAllCoins(page);
      final List<Coin> data = List.from(_coins)..addAll(new_data);
      data.sort((a,b) => a.compareTo(b));
      setState(() {
        _coins = data;
        _loading = false;
      });
    }catch (e){
      //In caso di errore, _loading viene rimesso a false in modo tale che l'app possa riprovare in un secondo momento
      _page--;
      _loading = false;
    }
  }

  //Funzione che popola la lista _coin alla creazione del widget
  Future<Null> getData() async {
    final data = await getAllCoins(1);
    setState(() {
      _coins = data;
    });
  }

}