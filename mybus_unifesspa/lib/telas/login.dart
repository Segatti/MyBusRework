import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:validadores/Validador.dart';
import 'package:geolocator/geolocator.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _keyForm = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();

  @override
  void initState() {
    getPermissaoLocalizacao();
    super.initState();
  }

  void getPermissaoLocalizacao() async{
    bool localAtivo;
    LocationPermission permissao;

    localAtivo = await Geolocator.isLocationServiceEnabled();
    if(!localAtivo){
      print("GPS Desativado!");
    }

    permissao = await Geolocator.checkPermission();
    if(permissao == LocationPermission.denied){

      permissao = await Geolocator.requestPermission();
      if(permissao == LocationPermission.deniedForever){
        print("Permissão Negada Permanentemente! O usuário tem que ir nas configurações para alterar...");
      }

      if(permissao == LocationPermission.denied){
        print("Permissão Negada!");
      }

    }else if(permissao == LocationPermission.always){
      print("Permissão para utilizar em segundo plano!");
    }else if(permissao == LocationPermission.whileInUse){
      print("Permissão para utilizar o GPS só quand o App está aberto!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/fundo.png"),
            fit: BoxFit.cover
          )
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  "images/logo.png",
                  width: 200,
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                  color: Colors.amber,
                  child: Form(
                    key: _keyForm,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 5),
                          child: TextFormField(
                            controller: _email,
                            decoration: InputDecoration(
                                hintText: "exemplo@email.com",
                                labelText: "E-mail",
                                labelStyle: TextStyle(
                                    color: Colors.blueAccent
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue)
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                    borderRadius: BorderRadius.circular(30)
                                ),
                                contentPadding: EdgeInsets.fromLTRB(25, 0, 25, 0)
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (valor){
                              return Validador().add(Validar.EMAIL, msg: "Adicione um email valido")
                                  .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: TextFormField(
                            controller: _senha,
                            decoration: InputDecoration(
                                hintText: "1234567",
                                labelText: "Senha",
                                labelStyle: TextStyle(
                                    color: Colors.blueAccent
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue)
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                    borderRadius: BorderRadius.circular(30)
                                ),
                                contentPadding: EdgeInsets.fromLTRB(25, 0, 25, 0)
                            ),
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            validator: (valor){
                              return Validador()
                                  .minLength(7, msg: "Tem que ter no mínimo 7 caracteres")
                                  .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 5, 10),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.person_add),
                          label: Text(
                              "Cadastrar",
                              style: TextStyle(fontSize: 18),
                          ),
                          onPressed: (){
                            Navigator.pushNamed(context, "cadastro");
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10)
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(5, 10, 15, 10),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.login),
                          label: Text(
                              "Entrar",
                              style: TextStyle(fontSize: 18),
                          ),
                          onPressed: (){
                            if(_keyForm.currentState.validate()){
                              FirebaseAuth firebase = FirebaseAuth.instance;
                              firebase.signInWithEmailAndPassword(email: _email.text, password: _senha.text).then((value){
                                Navigator.pushReplacementNamed(context, "mapa");
                              }).catchError((error){
                                print(error);
                                final snackBar = SnackBar(
                                  content: Text(
                                      "Usuário e/ou Senha errado!"
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              primary: Colors.green
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}
