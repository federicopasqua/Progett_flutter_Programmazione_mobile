import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//Creazione del database e restituisce riferimento ad esso
Future<Database> getDatabase() async{
  String path = join(await getDatabasesPath(), 'Database.db');
  return openDatabase(path, version: 2, onCreate: (db, version) {
    return db.execute(
      'CREATE TABLE transactions(id INTEGER, date INTEGER, type INTEGER, ticker TEXT, amount REAL, commissionTicker TEXT, commission REAL, value REAL, valueTicker TEXT)',
    );
  });
}

//Inserimento di una transazione
Future<void> insertTransaction(Transaction transaction) async {
  final db = await getDatabase();
  await db.insert(
    'transactions',
    transaction.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

//Eliminazione di una transazione per id
Future<void> deleteTransactionById(int id) async {
  final db = await getDatabase();
  await db.delete(
    'transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
}

//Ritorna tutte le transazioni di una singola moneta
Future<List<Transaction>> getTransactionsByTicker (String ticker) async {
  final db = await getDatabase();
  final List<Map<String, dynamic>> maps = await db.query(
    'transactions',
    where: 'ticker = ?',
    whereArgs: [ticker],
  );

  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(maps.length, (i) {
    return Transaction(
        id: maps[i]['id'],
        data: maps[i]['date'],
        type: maps[i]['type'],
        ticker: maps[i]['ticker'],
        amount: maps[i]['amount'],
        commissionTicker: maps[i]['commissionTicker'],
        commission: maps[i]['commission']
    );
  });
}

//Ritorna il saldo di tutte le monete
Future<List<Balance>> getBalances () async {
  final db = await getDatabase();
  final List<Map> list = await db.rawQuery('SELECT  id,  ticker , SUM(amount) as balance FROM transactions GROUP BY ticker');



  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(list.length, (i) {
    return Balance(
      id: list[i]['id'],
      ticker: list[i]['ticker'],
      balance: list[i]['balance'],
    );
  });
}

//Ritorna l'ultimo id nella tabella transazioni
Future<int> getLastId () async {
  final db = await getDatabase();
  final List<Map> list = await db.rawQuery('SELECT Max(id) as id FROM transactions');

  if (list[0]["id"] == null) return 0;
  return list[0]["id"];
}

//Ritorna il saldo di una singola moneta
Future<List<Balance>> getCoinBalance (String ticker) async {
  final db = await getDatabase();
  final List<Map> list = await db.rawQuery('SELECT id, ticker, (SELECT SUM(amount) FROM transactions where ticker = (?)) as balance FROM transactions WHERE ticker in (?)', [ticker, ticker]);

  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(list.length, (i) {
    return Balance(
      id: list[i]['id'],
      ticker: list[i]['ticker'],
      balance: list[i]['balance'],
    );
  });
}


//Classi che contengono i risultati delle query
class Transaction{
  final int id;
  final int data;
  final int type;
  final String ticker;
  final double amount;
  final String commissionTicker;
  final double commission;

  Transaction({required this.id, required this.data, required this.type, required this.ticker, required this.amount, required this.commissionTicker, required this.commission});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': data,
      'type': type,
      'ticker': ticker,
      'amount': amount,
      'commissionTicker': commissionTicker,
      'commission': commission,
    };
  }

  @override
  String toString() {
    return 'transactions{id: $id, date: $data, type: $type, ticker: $ticker, amount: $amount, commissionTicker: $commissionTicker, commission: $commission}';
  }
}

class Balance{
  final int id;
  final String ticker;
  final double balance;

  Balance({ required this.id, required this.ticker, required this.balance});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticker': ticker,
      'amount': balance
    };
  }

  @override
  String toString() {
    return 'transactions{id: $id, ticker: $ticker, balance: $balance}';
  }
}

