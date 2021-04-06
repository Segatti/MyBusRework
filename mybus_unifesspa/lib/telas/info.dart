import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Info extends StatelessWidget {

  final _url = "https://drive.google.com/file/d/1et3GstKKdGz_ADoXvsatYUR-F3vO9GcI/view?usp=sharing";

  _criarLinhaTable(String listaNomes, bool titulo) {
    return TableRow(
      children: listaNomes.split(';').map((name) {
        return Container(
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(
              fontSize: (titulo) ? 20.0 : 18.0,
              fontWeight: (titulo) ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: (titulo) ? TextAlign.center : TextAlign.justify,
          ),
          padding: EdgeInsets.all(8.0),
        );
      }).toList(),
    );
  }

  _divisor(){
    return TableRow(
        children: [
          Divider(
            color: Colors.black,
          ),
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Informações"
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Table(
              children: [
                _criarLinhaTable("MyBus", true),
                _divisor(),
                _criarLinhaTable("Periodo de desenvolvimento", true),
                _criarLinhaTable("2019-2020", false),
                _divisor(),
                _criarLinhaTable("Contato", true),
                _criarLinhaTable("bus.projeto@gmail.com", false),
                _divisor(),
                _criarLinhaTable("Participantes", true),
                _criarLinhaTable("Vittor Feitosa de Morais", false),
                _criarLinhaTable("Nadson Welkson P. de Souza", false),
                _criarLinhaTable("Gleison de Oliveira Medeiros", false),
                _divisor(),
                _criarLinhaTable("Objetivo", true),
                _criarLinhaTable("Este é um projeto da UNIFESSPA que tem como objetivo ser uma alternativa para localização do transporte público para qualquer cidade, onde qualquer pessoa pode compartilhar sua localização quando estiver utilziando um ônibus, táxi lotação ou moto táxi, com os demais usuários.", false),
                _divisor(),
                _criarLinhaTable("Termo de Uso", true),
                TableRow(
                  children: ['https://drive.google.com/file/d/1et3GstKKdGz_ADoXvsatYUR-F3vO9GcI/view?usp=sharing'].map((url) {
                    return Container(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.open_in_browser),
                        onPressed: () async{
                          await canLaunch(_url) ? await launch(_url) : throw 'Não conseguiu iniciar $_url';
                        },
                        label: Text('Abrir documento'),
                      ),
                      padding: EdgeInsets.all(8.0),
                    );
                  }).toList(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
