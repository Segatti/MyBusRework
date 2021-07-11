import 'package:flutter/material.dart';
import 'package:mybus_unifesspa/telas/cadastro.dart';
import 'package:mybus_unifesspa/telas/feedback.dart';
import 'package:mybus_unifesspa/telas/info.dart';
import 'package:mybus_unifesspa/telas/login.dart';
import 'package:mybus_unifesspa/telas/mapa.dart';
import 'package:mybus_unifesspa/telas/tutorial.dart';

class Rotas{
  static Route<dynamic> gerarRotas(RouteSettings routeSettings){
    switch (routeSettings.name) {
      case "login":
        return MaterialPageRoute(builder: (_) => Login());
      case "cadastro":
        return MaterialPageRoute(builder: (_) => Cadastro());
      case "tutorial":
        return MaterialPageRoute(builder: (_) => Tutorial());
      case "mapa":
        return MaterialPageRoute(builder: (_) => Mapa());
      case "info":
        return MaterialPageRoute(builder: (_) => Info());
      case "feedback":
        return MaterialPageRoute(builder: (_) => FeedbackApp());
      default:
        return _erroRota();
    }
  }

  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Tela não encontrada!"),
        ),
        body: Center(
          child: Text("Tela não encontrada!"),
        ),
      );
    });
  }
}