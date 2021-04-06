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
    runApp(
        MaterialApp(
          title: "MyBus - Unifesspa",
          theme: temaPadrao,
          initialRoute: "login",
          onGenerateRoute: Rotas.gerarRotas,
          debugShowCheckedModeBanner: false,
        )
    );
  });
}