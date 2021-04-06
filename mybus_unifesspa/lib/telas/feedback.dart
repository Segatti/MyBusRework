import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:validadores/Validador.dart';

class FeedbackApp extends StatelessWidget {
  
  final _keyForm = GlobalKey<FormState>();
  final TextEditingController _msg = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Feedback"
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Text(
              "Ajude-nos a melhorar cada vez mais! Use o campo abaixo para reportar erros ou dar dicas de melhorias, sua ajuda é sempre bem vinda. (25 - 500 caracteres)"
            ),
          ),
          Expanded(
            child: Form(
              key: _keyForm,
              child: TextFormField(
                controller: _msg,
                maxLength: 500,
                maxLines: null,
                validator: (valor){
                  return Validador()
                      .maxLength(500, msg: "Por favor, seja objetivo e claro... máximo de 500 caracteres!")
                      .minLength(25, msg: "Não precisa poupar palavras... mínimo de 25 caracteres!")
                      .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                },
              ),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              child: Text(
                "Enviar"
              ),
              onPressed: (){
                if(_keyForm.currentState.validate()){
                  FirebaseFirestore firebase = FirebaseFirestore.instance;
                  firebase.collection("Feedback").add({"msg":_msg.text}).then((value){
                    print("Feedback enviado com sucesso!");
                    final snackBar = SnackBar(
                      content: Text(
                          "Enviado com sucesso!"
                      ),
                      backgroundColor: Colors.green,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  }).catchError((error){
                    print(error);
                    final snackBar = SnackBar(
                      content: Text(
                          "Houve um erro ao enviar!"
                      ),
                      backgroundColor: Colors.red,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
