import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mybus_unifesspa/rotas.dart';

final ThemeData temaPadrao = ThemeData(
  primaryColor: Colors.indigo,
  accentColor: Colors.black26,
);

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_){
    FirebaseAuth firebase = FirebaseAuth.instance;
    User usuario = firebase.currentUser;
    runApp(
        MaterialApp(
          title: "WikiBus - Unifesspa",
          theme: temaPadrao,
          initialRoute: (usuario != null) ? "mapa" : "login", //Abre a tela de login, caso não esteja logado!
          onGenerateRoute: Rotas.gerarRotas,
          debugShowCheckedModeBanner: false,
        )
    );
  });
}