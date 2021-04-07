import 'package:cloud_firestore/cloud_firestore.dart';

class Transporte{
  String nome;
  String tipo;
  String destino;
  GeoPoint local;

  Transporte(this.nome, this.tipo, this.destino, this.local);

  Map<String, dynamic> toMap(){
    return {
      "nome":this.nome,
      "tipo":this.tipo,
      "destino":this.destino,
      "localAtual":this.local,
      "ultimaAtualizacao":DateTime.now()
    };
  }
}