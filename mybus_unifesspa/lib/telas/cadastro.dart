import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mybus_unifesspa/classes/Usuario.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validadores/Validador.dart';

class Cadastro extends StatelessWidget {

  final _keyForm = GlobalKey<FormState>();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();
  final TextEditingController _cidade = TextEditingController();
  final TextEditingController _q1 = TextEditingController();
  final TextEditingController _q2 = TextEditingController();
  final TextEditingController _q3 = TextEditingController();
  final TextEditingController _q4 = TextEditingController();

  final _url = "https://drive.google.com/file/d/1et3GstKKdGz_ADoXvsatYUR-F3vO9GcI/view?usp=sharing";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Form(
          key: _keyForm,
          child: Column(
            children: [
              TextFormField(
                controller: _nome,
                decoration: InputDecoration(
                    labelText: "Nome Completo"
                ),
                keyboardType: TextInputType.text,
                validator: (valor){
                  return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                },
              ),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(
                    labelText: "E-mail",
                    hintText: "exemplo@email.com"
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (valor){
                  return Validador()
                      .add(Validar.EMAIL, msg: "Adicione um email valido")
                      .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                },
              ),
              TextFormField(
                controller: _senha,
                decoration: InputDecoration(
                    labelText: "Senha",
                    hintText: "mínimo 7 caracteres, ex: 1234567"
                ),
                keyboardType: TextInputType.text,
                obscureText: true,
                validator: (valor){
                  return Validador()
                      .minLength(7, msg: "Tem que ter no mínimo 7 caracteres")
                      .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: 25),
                child: Row(
                    children: <Widget>[
                      Expanded(
                          child: Divider()
                      ),

                      Text("Questionário"),

                      Expanded(
                          child: Divider()
                      ),
                    ]
                )
              ),
              TextFormField(
                controller: _cidade,
                decoration: InputDecoration(
                    labelText: "Cidade - Estado",
                    hintText: "ex: Marabá - PA"
                ),
                keyboardType: TextInputType.text,
                validator: (valor){
                  return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "O quão importante você acredita que é este tipo de aplicativo? 1(Sem importância) à 5(Muito importante)",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _q1,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        validator: (valor){
                          return Validador()
                              .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório")
                              .minVal(1, msg: "Valor mínimo é 1")
                              .maxVal(5, msg: "Valor máximo é 5").valido(valor);
                        },
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Em média, quantos transportes públicos você pega diariamente?",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _q2,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator: (valor){
                          return Validador()
                              .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório")
                              .minVal(1, msg: "Valor mínimo é 1").valido(valor);
                        },
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Em média, quanto tempo(minutos) você espera em paradas?",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _q3,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator: (valor){
                          return Validador()
                              .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório")
                              .minVal(1, msg: "Valor mínimo é 1").valido(valor);
                        },
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Que nota você daria para o transporte público de sua cidade? 1(péssimo) à 5(Ótimo)",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _q4,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        validator: (valor){
                          return Validador()
                              .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório")
                              .minVal(1, msg: "Valor mínimo é 1")
                              .maxVal(5, msg: "Valor máximo é 5").valido(valor);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Atenção, ao se cadastrar você estará automaticamente concordando com os Termos de Uso do aplicativo WikiBus",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.open_in_browser),
                      label: Text(
                          "Abrir documento"
                      ),
                      onPressed: () async{
                        await canLaunch(_url) ? await launch(_url) : throw 'Não conseguiu iniciar $_url';
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.assignment_turned_in),
                      label: Text(
                          "Cadastrar",
                          style: TextStyle(fontSize: 15),
                      ),
                      onPressed: (){
                        if(_keyForm.currentState.validate()){
                          FirebaseAuth firebase = FirebaseAuth.instance;
                          firebase.createUserWithEmailAndPassword(email: _email.text, password: _senha.text).then((value){
                            String id = value.user.uid;
                            Usuario usuario = Usuario(_nome.text, _email.text, _senha.text, _cidade.text, int.parse(_q1.text), int.parse(_q2.text), int.parse(_q3.text), int.parse(_q4.text));
                            FirebaseFirestore firebase = FirebaseFirestore.instance;
                            firebase.collection("Usuarios").doc(id).set(usuario.toMap()).then((value){
                              final snackBar = SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                    "Cadastrado com sucesso!"
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              Navigator.pop(context);
                            });
                          }).catchError((error){
                            print(error);
                            final snackBar = SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                  "Houve um erro ao cadastrar!"
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
                  )
                ],
              )
            ],
          ),
        ),
      )
    );
  }
}
