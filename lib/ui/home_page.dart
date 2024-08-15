import 'dart:io';
import 'package:agenda_contatos/ui/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:agenda_contatos/helpers/contact_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

enum OrderOptions { orderaz, orderza }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ContactHelper helper = ContactHelper();
  List<Contact> contacts = [];
  late Contact _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _getAllContact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Contatos",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          PopupMenuButton<OrderOptions>(
            itemBuilder: (context) =>
            <PopupMenuEntry<OrderOptions>>[
              const PopupMenuItem<OrderOptions>(
                child: Text("Ordenar de A-Z"),
                value: OrderOptions.orderaz,
              ),
              const PopupMenuItem<OrderOptions>(
                child: Text("Ordenar de Z-A"),
                value: OrderOptions.orderza,
              ),
            ],
            onSelected: _orderList,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showContactPage();
        },
        child: Icon(Icons.add),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return _contactCard(context, index);
        },
      ),
    );
  }

  Widget _contactCard(BuildContext context, int index) {
    final contact = contacts[index];
    final imageProvider =
    contact.img.isNotEmpty && File(contact.img).existsSync()
        ? FileImage(File(contact.img))
        : AssetImage("images/person.png") as ImageProvider;

    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: GestureDetector(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name ?? "",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contact.email ?? "",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        contact.phone ?? "",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          _showOptions(context, index);
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = contact; // Armazena o contato removido
          _lastRemovedPos = index;
          contacts.removeAt(index); // Remove da lista local
        });

        // Exclua o contato do banco de dados
        helper.deleteContact(contact.id).then((_) {
          // Exiba o SnackBar
          final snackBar = SnackBar(
            content: Text("Contato ${_lastRemoved.name} removido"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  contacts.insert(_lastRemovedPos, _lastRemoved); // Adiciona o contato de volta na lista local
                  // Atualize a lista após desfazer a remoção, se necessário
                });
              },
            ),
            duration: Duration(seconds: 5), // Aumente o tempo se necessário
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }).catchError((error) {
          print('Erro ao excluir contato: $error');
          // Se desejar, você pode reverter a remoção do contato em caso de erro
        });
      },
    );
  }




  void _showOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomSheet(
          onClosing: () {},
          builder: (context) {
            return Container(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        launch("tel:${contacts[index].phone}");
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Ligar",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showContactPage(contact: contacts[index]);
                      },
                      child: Text(
                        "Editar",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        helper.deleteContact(
                          contacts[index].id,
                        );
                        setState(() {
                          contacts.removeAt(index);
                          Navigator.pop(context);
                        });
                      },
                      child: Text(
                        "Excluir",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showContactPage({Contact? contact}) async {
    final recContact = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactPage(contact: contact ?? Contact()),
      ),
    );

    if (recContact != null) {
      if (contact != null) {
        await helper.updateContact(recContact);
        Fluttertoast.showToast(
          msg: "Contato atualizado!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        await helper.saveContact(recContact);
        Fluttertoast.showToast(
          msg: "Contato salvo!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
      _getAllContact(); // Atualiza a lista de contatos
    } else {
      Fluttertoast.showToast(
        msg: "Nenhum contato retornado.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _getAllContact() {
    helper.getAllContacts().then((list) {
      // Verifique a lista recebida antes de atualizar o estado
      print('Lista de contatos recebida do banco de dados: $list');

      setState(() {
        contacts = list;
      });

      // Verifique a lista atualizada após definir o estado
      print('Contatos atualizados no estado: $contacts');
    }).catchError((error) {
      // Adicione tratamento de erros para casos em que a obtenção falhe
      print('Erro ao obter contatos: $error');
    });
  }


  void _orderList(OrderOptions result) {
    switch (result) {
      case OrderOptions.orderaz:
        contacts.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case OrderOptions.orderza:
        contacts.sort(
                (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    setState(() {});
  }
}
