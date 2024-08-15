import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final String contactTable = "contactTable";
final String idColumn = "idColumn";
final String nameColumn = "nameColumn";
final String emailColumn = "emailColumn";
final String phoneColumn = "phoneColumn";
final String imgColumn = "imgColumn";

class ContactHelper {
  static final ContactHelper _instance = ContactHelper.internal();

  factory ContactHelper() => _instance;

  ContactHelper.internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "contacts.db");

    return await openDatabase(path, version: 1, onCreate: (Database db, int newerVersion) async {
      await db.execute(
          "CREATE TABLE $contactTable($idColumn INTEGER PRIMARY KEY AUTOINCREMENT, $nameColumn TEXT, $emailColumn TEXT, $phoneColumn TEXT, $imgColumn TEXT)"
      );
    });
  }

  Future<Contact> saveContact(Contact contact) async {
    Database dbContact = await db;

    if (contact.id == 0) {
      // Novo contato
      contact.id = await dbContact.insert(contactTable, contact.toMap());
    } else {
      // Atualização de contato
      await dbContact.update(
        contactTable,
        contact.toMap(),
        where: "$idColumn = ?",
        whereArgs: [contact.id],
      );
    }

    return contact;
  }




  Future<Contact?> getContact(int id) async {
    Database dbContact = await db;
    List<Map<String, dynamic>> maps = await dbContact.query(contactTable,
        columns: [idColumn, nameColumn, emailColumn, phoneColumn, imgColumn],
        where: "$idColumn = ?",
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> deleteContact(int id) async {
    Database dbContact = await db;
    return await dbContact.delete(contactTable, where: "$idColumn = ?", whereArgs: [id]);
  }

  Future<int> updateContact(Contact contact) async {
    Database dbContact = await db;
    return await dbContact.update(
      contactTable,
      contact.toMap(),
      where: "$idColumn = ?",
      whereArgs: [contact.id],
    );
  }

  Future<List<Contact>> getAllContacts() async {
    Database dbContact = await db;
    List<Map<String, dynamic>> listMap = await dbContact.rawQuery("SELECT * FROM $contactTable");
    List<Contact> listContact = [];
    for (Map<String, dynamic> m in listMap) {
      listContact.add(Contact.fromMap(m));
    }
    print('Lista de contatos obtida: $listContact'); // Mensagem de depuração
    return listContact;
  }


  Future<int?> getNumber() async {
    Database dbContact = await db;
    List<Map<String, dynamic>> result = await dbContact.rawQuery("SELECT COUNT(*) FROM $contactTable");
    return Sqflite.firstIntValue(result);
  }

  Future<void> close() async {
    Database dbContact = await db;
    await dbContact.close();
  }
}

class Contact {
  int id;
  String name;
  String email;
  String phone;
  String img;

  Contact({
    this.id = 0, // ID deve começar como 0 para ser gerado automaticamente
    this.name = '',
    this.email = '',
    this.phone = '',
    this.img = '',
  });

  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {};
    if (id != 0) map[idColumn] = id; // Adiciona o ID apenas se for diferente de 0
    map[nameColumn] = name;
    map[emailColumn] = email;
    map[phoneColumn] = phone;
    map[imgColumn] = img;
    return map;
  }

  static Contact fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map[idColumn] as int,
      name: map[nameColumn] as String,
      email: map[emailColumn] as String,
      phone: map[phoneColumn] as String,
      img: map[imgColumn] as String,
    );
  }

  @override
  String toString() {
    return "Contact(id: $id, name: $name, email: $email, phone: $phone, img: $img)";
  }
}

