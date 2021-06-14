import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:progetto_flut/database/database.dart';
import 'package:progetto_flut/network/network.dart';



class insertCoin extends StatefulWidget{

  final Coin coin;
  insertCoin(this.coin);

  @override
  State<StatefulWidget> createState() => _insertCoin();

}

class _insertCoin extends State<insertCoin>{

  //Variabile che contiene le infromazioni della moneta che si vuole inserire
  var _coin;

  //Key necessaria per far funzionare la form
  final _formKey = GlobalKey<FormState>();
  //Lista per convertire i tipi di transazioni da intero a stringa
  final states = ["Buy", "Sell", "Transfer In", "Transfer Out", "Mining", "Stacking"];

  //Tutte le variabili che possono essere inserite nella form
  var type = "Buy";
  var buy;
  var buyTicker;
  var exchangeOf;
  var price;
  var commission = 0.0;
  var commissionTicker = "eur";

  //Variabile che contiene tutti i ticker accettati
  var _allTickers;

  //Controller dei campi
  final controllerBuyTicker = TextEditingController();
  final controllerExchangeOf = TextEditingController();
  final controllerCommissionTicker = TextEditingController();

  @override
  void initState() {
    super.initState();
    //La variabile _coin viene passata dal widget che chiama questo
    _coin = widget.coin;
    //Il ticker principale viene settato al ticker della moneta selezionata
    buyTicker = _coin.id;
    //Viene aggiornata la lista dei ticker accettati
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                      "New Transaction",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: DropdownButtonFormField(

                    value: type,
                    items: states.map((state){
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (newValue){
                      setState(() {
                        type = newValue.toString();
                      });
                    },
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                //Verifica che il campo non sia vuoto
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                final number = num.tryParse(value);
                                if (number == null){
                                  return "Insert a number";
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                              onChanged: (String? value) {
                                if (value != null)
                                  setState(() {
                                    buy = num.tryParse(value);
                                  });

                              },
                            )
                        )
                    ),
                    Expanded(
                        child: Padding(
                          padding: new EdgeInsets.all(10.0),
                          child: TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'ticker',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _coin.symbol,
                          ),
                        )
                    )
                  ],
                ),
                //La parte inferiore della form è mostrata solo in caso sia una transazione di tipo Buy o Sell
                if ((type == "Buy" || type == "Sell")) _bottomForm(),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            //Tutti i dati già validati vengono inseriti nel database e si torna al widget precedente passando true indicando che una transazione è stata inserita
                            final form = _formKey.currentState!;
                            if (form.validate()) {
                              form.save();
                              final nType = states.indexOf(type);
                              final id = await getLastId() + 1;
                              final amount = nType == 1 || nType == 3 ? -buy : buy;
                              insertTransaction(Transaction(id: id, data: DateTime.now().millisecondsSinceEpoch, type: nType, ticker: buyTicker, amount: amount.toDouble(), commissionTicker: commissionTicker, commission: commission.toDouble()));
                              switch (nType){
                                case 0:{
                                  insertTransaction(Transaction(id: id, data: DateTime.now().millisecondsSinceEpoch, type: 1, ticker: exchangeOf, amount: (-buy*price).toDouble(), commissionTicker: commissionTicker, commission: 0.0));

                                }break;
                                case 1:{
                                  insertTransaction(Transaction(id: id, data: DateTime.now().millisecondsSinceEpoch, type: 0, ticker: exchangeOf, amount: (buy*price).toDouble(), commissionTicker: commissionTicker, commission: 0.0));

                                }break;
                              }

                              Navigator.pop(context, true);
                            }
                          },
                          child: Text('Submit'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }


  //Parte inferiore della form
  Widget _bottomForm(){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10.0),
          child: TypeAheadFormField<Coin?>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: controllerExchangeOf,
              decoration: InputDecoration(
                labelText: 'InExchangeOf',
                border: OutlineInputBorder(),
              ),
            ),
            //Mostra i suggerimenti
            suggestionsCallback: (String query) =>
                _allTickers.where((Coin option) {
                  return option.name.toLowerCase().contains(query.toLowerCase()) || option.symbol.toLowerCase().contains(query.toLowerCase());
                }).toList(),
            itemBuilder: (context, Coin? suggestion) => ListTile(
              title: Text(suggestion!.name),
            ),
            onSuggestionSelected: (Coin? suggestion) =>  controllerExchangeOf.text = suggestion!.id,
            //Validazione del valore aggiunto. Quato deve essere presente nella lista _allTickers
            validator: (value) => (type != "Buy" || type != "Sell") && (value == null || value.isEmpty || !_allTickers.map((v) => v.id.toLowerCase()).contains(value.toLowerCase()) ) ? 'Please select a ticker' : null,
            onSaved: (value) => setState(() => exchangeOf = value),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10.0),
          child: TextFormField(
            validator: (value) {
              //Validazione
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              final number = num.tryParse(value);
              if (number == null){
                return "Insert a number";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
            onSaved: (String? value) {
              if (value != null)
                price = num.tryParse(value);
            },
          ),
        ),
        Row(
          children: [
            Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      final number = num.tryParse(value);
                      if (number == null){
                        return "Insert a number";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Commission',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                    onSaved: (String? value) {
                      if (value != null && num.tryParse(value) != null)
                        commission = num.tryParse(value)!.toDouble();
                    },
                  ),
                )
            ),

            Expanded(
                child: Padding(
                  padding: new EdgeInsets.all(10.0),
                  child: TypeAheadFormField<Coin?>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: controllerCommissionTicker,
                      decoration: InputDecoration(
                        labelText: 'ticker',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    //Mostra i suggerimenti
                    suggestionsCallback: (String query) =>
                        _allTickers.where((Coin option) {
                          return option.symbol.toLowerCase().contains(query.toLowerCase()) || option.name.toLowerCase().contains(query.toLowerCase());
                        }).toList(),
                    itemBuilder: (context, Coin? suggestion) => ListTile(
                      title: Text(suggestion!.name),
                    ),
                    onSuggestionSelected: (Coin? suggestion) =>  controllerCommissionTicker.text = suggestion!.id,
                    //Validazione del valore aggiunto. Quato deve essere presente nella lista _allTickers
                    validator: (value) => (type != "Buy" || type != "Sell") && (value == null || value.isEmpty || !_allTickers.map((v) => v.id.toLowerCase()).contains(value.toLowerCase())) ? 'Please select a ticker' : null,
                    onSaved: (value) => setState(() => commissionTicker = value == null ? "eur" : value),
                  ),
                )
            ),
          ],
        )
      ],
    );
  }

  //Funzione che aggiorna i tutti i ticker ammessi
  Future<Null> getData() async {
    final data = await getAllCoinsReduced();
    setState(() {
      _allTickers = data;
    });
  }

}