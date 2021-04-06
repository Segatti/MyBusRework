import 'package:flutter/material.dart';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MyBus"),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: (){
              Navigator.pushNamed(context, "info");
            },
          ),
          IconButton(
            icon: Icon(Icons.email_outlined),
            onPressed: (){
              Navigator.pushNamed(context, "feedback");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Text(
              "Eu → Ponto: ∞"
            ),
          ),
          Expanded(
            child: Text("Mapa"),
          ),
          Expanded(
            child: ElevatedButton(
              child: Text(
                ""
              ),
              onPressed: (){
                //Buscar o ponto mais proximo
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              child: Icon(Icons.directions_bus),
              onPressed: (){
                //Criar transporte
              },
            ),
          )
        ],
      ),
    );
  }
}
