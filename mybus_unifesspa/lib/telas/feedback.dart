import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:validadores/Validador.dart';

class FeedbackApp extends StatelessWidget {
  
  final _keyForm = GlobalKey<FormState>();
  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Feedback"
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
                "Ajude-nos a melhorar cada vez mais! Use o campo abaixo para reportar erros ou dar dicas de melhorias, sua ajuda é sempre bem vinda."
            ),
            Form(
              key: _keyForm,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: "Título",
                        hintText: "Todo bom texto tem um título..."
                    ),
                    controller: _titulo,
                    maxLength: 50,
                    maxLines: 1,
                    validator: (valor){
                      return Validador()
                          .maxLength(50, msg: "Por favor, seja objetivo e claro... máximo de 50 caracteres!")
                          .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: "Mensagem",
                        hintText: "Sinta-se livre para escrever sua opinião!"
                    ),
                    controller: _msg,
                    maxLength: 500,
                    maxLines: null,
                    validator: (valor){
                      return Validador()
                          .maxLength(500, msg: "Por favor, seja objetivo e claro... máximo de 500 caracteres!")
                          .minLength(25, msg: "Não poupe palavras... mínimo de 25 caracteres!")
                          .add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                    },
                  ),
                ],
              )
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.mark_email_read),
                    label: Text(
                        "Enviar"
                    ),
                    onPressed: (){
                      if(_keyForm.currentState.validate()){
                        FirebaseFirestore firebase = FirebaseFirestore.instance;
                        firebase.collection("Feedback").add({"titulo":_titulo.text ,"msg":_msg.text}).then((value){
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
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        primary: Colors.green
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}
