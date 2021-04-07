import 'package:cloud_firestore/cloud_firestore.dart';

class PontoBus{
  String nome;
  String descricao;
  GeoPoint local;

  PontoBus(this.nome, this.descricao, this.local);

  Map<String, dynamic> toMap(){
    return {
      "nome":this.nome,
      "descricao":this.descricao,
      "localAtual":this.local
    };
  }
}