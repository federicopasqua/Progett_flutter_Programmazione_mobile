import 'package:http/http.dart' as http;
import 'dart:convert';


//Permette di scarivare tutti i dettagli delle coin dell API paginate
Future<List<Coin>> getAllCoins(int page) async {
  Map<String, String> queryParameters = {
    "vs_currency": "eur",
    "page" : page.toString(),
    "price_change_percentage" : "1h,24h,7d"
  };
  final url = Uri.https('api.coingecko.com','/api/v3/coins/markets', queryParameters);
  final response = await http.get(url);

  if (response.statusCode == 200){
    List coins = json.decode(response.body);
    return coins.map((coin) => new Coin.fromJson(coin)).toList();
  }
  else
    throw Exception("Nessuna connessione ad Internet");
}

//Permette di scaricare i dettagli di una singola coin
Future<List<Coin>> getSpecificCoins(List coins) async {
  Map<String, String> queryParameters = {
    "vs_currency": "eur",
    "ids" : coins.join(","),
    "price_change_percentage" : "1h,24h,7d"
  };
  final url = Uri.https('api.coingecko.com','/api/v3/coins/markets', queryParameters);
  final response = await http.get(url);

  if (response.statusCode == 200){
    List coins = json.decode(response.body);
    return coins.map((coin) => new Coin.fromJson(coin)).toList();
  }
  else
    throw Exception("Nessuna connessione ad Internet");
}

//permette di scaricare la lista di tutte le coin in modo non paginato ma con dettagli ridotti (solo nome e ticker)
Future<List<Coin>> getAllCoinsReduced() async {
  final url = Uri.https('api.coingecko.com','/api/v3/coins/list');
  final response = await http.get(url);

  if (response.statusCode == 200){
    List coins = json.decode(response.body);
    return coins.map((coin) => new Coin.fromJson(coin)).toList();
  }
  else
    throw Exception("Nessuna connessione ad Internet");
}

//Classe che contiene i dati json ritornati dalle API
class Coin{
  final String id;
  final String name;
  final String symbol;
  final String? price;
  final String? imageUrl;
  final String? marketCap;
  final int? marketCapRank;
  final String? percentage1h;
  final String? percentage24h;
  final String? percentage7d;
  final String? volume;
  final String? supply;
  final String? high;
  final String? low;

  Coin({required this.id, required this.name, required this.symbol, this.price, this.imageUrl, this.marketCap, this.marketCapRank, this.percentage1h, this.percentage24h, this.percentage7d, this.volume, this.supply, this.high, this.low});


  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      price: json['current_price'].toString(),
      imageUrl: json['image'],
      marketCap: json['market_cap'].toString(),
      marketCapRank: json['market_cap_rank'],
      percentage1h: json["price_change_percentage_1h_in_currency"].toString(),
      percentage24h: json['price_change_percentage_24h_in_currency'].toString(),
      percentage7d: json['price_change_percentage_7d_in_currency'].toString(),
      volume: json['total_volume'].toString(),
      supply: json['circulating_supply'].toString(),
      high: json['high_24h'].toString(),
      low: json['low_24h'].toString(),
    );
  }

  @override
  int compareTo(other) {

    if (this.marketCapRank == null && other.marketCapRank != null) {
      return 1;
    }

    if (this.marketCapRank != null && other.marketCapRank == null) {
      return -1;
    }

    if (this.marketCapRank == null || other.marketCapRank == null) {
      return 0;
    }

    if (this.marketCapRank! > other.marketCapRank!) {
      return 1;
    }

    if (this.marketCapRank! < other.marketCapRank!) {
      return -1;
    }


    return 0;
  }

}
