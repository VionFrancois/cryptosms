import 'package:flutter/material.dart';
import '../back/db.dart';
import '../back/messages_manager.dart';

class NewContactPage extends StatefulWidget {
  @override
  _NewContactPageState createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  @override

  // TODO : Changer ces valeurs avec les champs textes
  String phoneNumber = "000000000";
  String name = "Bob";

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Contact"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person),
            Text('Prénom'),
            TextFormField(
              decoration: InputDecoration(
              //labelText: 'Prénom',
              //prefixIcon:
              hintText: 'Entrez le prénom',
              ),
            ),
            SizedBox(height: 16),
            Text('Nom'),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Entrez le nom',
              ),
            ),
            SizedBox(height: 16),
            Icon(Icons.phone),
            Text('Téléphone'),
            Row(
              children: [
                DropdownButton<String>(
                  value: 'BE +32', // Country code
                  onChanged: (newValue) {},
                  items: <String>['BE +32', 'FR +33', '+1', '+44']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Entrez le numéro de téléphone',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Ajouter des informations'),
            ),



      ]
      ),

    ),
    floatingActionButton: FloatingActionButton(
        onPressed: () async {
      Contact? newContact = await createContact(phoneNumber,name);
      if(newContact != null){
          initHandshake(newContact);
      }
      print("Hello there");
    },
    tooltip: 'Enregistrer',
    child: const Icon(Icons.save, color: Colors.white),
    backgroundColor: Colors.blue,
    ),

    );


  }
}
