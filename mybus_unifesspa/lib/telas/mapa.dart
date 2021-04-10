import 'dart:async';
import 'dart:convert';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mybus_unifesspa/classes/PontoBus.dart';
import 'package:mybus_unifesspa/classes/Transporte.dart';
import 'package:validadores/Validador.dart';
import 'package:http/http.dart' as http;

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  //Mapa
  MapboxMapController mapController;
  bool mapboxLocalizacao = false;
  Symbol _symbolSelecionado;
  List<GeoPoint> _rotaGerada = [];

  //Geral
  String _txtBtnBuscar = "Buscar Ponto de Ônibus";
  String _txtTimeBus = "Eu → Ponto: ∞";
  Color _btnBuscar = Colors.blue;
  Color _btnTransporte = Colors.grey.withOpacity(0.7);
  bool _busAtivo = false;
  bool _rotaAtiva = false;

  //Usuário
  bool permissaoLocal;
  Position _position;

  //Transporte
  String _janelaTransporteTitulo = "Criar Transporte";
  String _btnJanelaTransporteConfirmar = "Criar";
  Color _btnJanelaTransporteConfirmarCor = Colors.green;
  final _keyFormTransporte = GlobalKey<FormState>();
  String _tipoSelecionado = "bus";
  TextEditingController _destinoTransporte = TextEditingController();
  Map<String, dynamic> _dadosTransporte = Map<String, dynamic>();
  Map<String, dynamic> _symbolTransporte = Map<String, dynamic>();
  bool _modoEspera = false;

  //PontoBus
  String _janelaPontoBusTitulo = "Criar Ponto";
  TextEditingController _nomePontoBus = TextEditingController();
  TextEditingController _descricaoPontoBus = TextEditingController();
  final _keyFormPontoBus = GlobalKey<FormState>();
  Map<String, dynamic> _dadosPontoBus = Map<String, dynamic>();
  Map<String, dynamic> _symbolPontoBus = Map<String, dynamic>();

  @override
  void initState(){
    getPermissaoLocalizacao();
    super.initState();
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void _onSymbolTapped(Symbol symbol){
    if(_symbolSelecionado != null){
      mapController.updateSymbol(
        _symbolSelecionado,
        SymbolOptions(iconSize: 1.2)
      );
    }

    _symbolSelecionado = symbol;

    mapController.updateSymbol(
      _symbolSelecionado,
      SymbolOptions(iconSize: 1.5)
    );

    if(_symbolSelecionado.options.iconImage != ""){//Removendo os symbol pré carregados que não tem icone
      if(_symbolSelecionado.options.iconImage == "bus"){//Foi selecionado o ponto de ônibus
        String _id = _symbolSelecionado.options.textTransform;
        janelaPontoBusMapBox(_id);
      }else{//Selecionado algum transporte
        String _id = _symbolSelecionado.options.textTransform;
        print(_id);
        janelaTransporteMapBox(_id);
      }
    }

  }

  void _onStyleLoadedCallback() {
    print("Mapa carregado!");
    carregarPontoBus();
    carregarTransporte();
    mapController.onSymbolTapped.add((_onSymbolTapped));
  }

  void carregarPontoBus(){
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("PontoBus").snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((dados) async{
        if(dados.type == DocumentChangeType.added){
          //Adicionado ao firebase(Quando abre a requisição, vai ser carregado os dados como se tivessem sido adicionados ao firebase)
          String _id = dados.doc.id;
          _dadosPontoBus.putIfAbsent(_id, () => dados.doc.data());
          Symbol symbol = await mapController.addSymbol(
            SymbolOptions(
              textField: _dadosPontoBus[_id]['nome'],
              textTransform: _id,//Isso é um "atalho", evita muito código de busca para encontrar o dado, não retirar a menos que encontre um método mais otimizado
              textAnchor: 'top',
              iconImage: 'bus',
              iconSize: 1.2,
              iconAnchor: 'bottom',
              geometry: LatLng(
                _dadosPontoBus[_id]['localAtual'].latitude,
                _dadosPontoBus[_id]['localAtual'].longitude
              ),
            ),
          );
          _symbolPontoBus.putIfAbsent(_id, () => symbol);
          print("Dado adicionado! ${_dadosPontoBus[_id]}");
        }else if(dados.type == DocumentChangeType.modified){
          //Atualizado no firebase
          String _id = dados.doc.id;
          _dadosPontoBus[_id] = dados.doc.data();
          await mapController.updateSymbol(
            _symbolPontoBus[_id],
            SymbolOptions(
              textField: _dadosPontoBus[_id]['nome']
            )
          );
          print("Dado atualizado! ${_dadosPontoBus[_id]}");
        }else if(dados.type == DocumentChangeType.removed){
          //Removido do firebase
          String _id = dados.doc.id;
          if(_symbolSelecionado == _symbolPontoBus[_id]) _symbolSelecionado = null; //Caso eu esteja deletando o symbol selecionado
          await mapController.removeSymbol(_symbolPontoBus[_id]);
          _dadosPontoBus.remove(_id);
          _symbolPontoBus.remove(_id);
          print("Dado removido! ${dados.doc.data()}");
        }
      });
    });
  }

  void carregarTransporte(){
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("Transporte").snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((dados) async{
        if(dados.type == DocumentChangeType.added){
          //Adicionado ao firebase(Quando abre a requisição, vai ser carregado os dados como se tivessem sido adicionados ao firebase)
          String _id = dados.doc.id;
          _dadosTransporte.putIfAbsent(_id, () => dados.doc.data());
          /*Atenção - Muito importante
          * Os symbols que serve para representar o transporte devem ser "pré carregados"
          * antes de pode utilizar, isso porque o symbol quando adicionado a primeira vez
          * já se torna a posição PERMANENTE, ou seja, não tem como mover de local
          * e caso tente mudar a posição vai haver uma duplicação, e somente a duplicação
          * vai poder se mover livremente, tendo isso em mente, escolhi por deixar
          * invisivel o symbol que fica permanente e só quando é atualizado o transporte(duplicata),
          * é quando vai aparecer no mapa, espero que tenha entendido, futuro programador kkkkk.
          * */
          Symbol symbol = await mapController.addSymbol(
            SymbolOptions(
                geometry: LatLng(
                    _dadosTransporte[_id]['localAtual'].latitude,
                    _dadosTransporte[_id]['localAtual'].longitude
                )
            ),
          );
          _symbolTransporte.putIfAbsent(_id, () => symbol);
          print("Dado adicionado! ${_dadosTransporte[_id]}");
        }else if(dados.type == DocumentChangeType.modified){
          //Atualizado no firebase
          String _id = dados.doc.id;
          _dadosTransporte[_id] = dados.doc.data();
          await mapController.updateSymbol(
              _symbolTransporte[_id],
              SymbolOptions(
                  textField: _dadosTransporte[_id]['nome'],
                  textTransform: _id,//Isso é um "atalho", evita muito código de busca para encontrar o dado, não retirar a menos que encontre um método mais otimizado
                  textAnchor: 'top',
                  iconImage: getIcone(_dadosTransporte[_id]['tipo']),
                  iconSize: 1.2,
                  iconAnchor: 'bottom',
                  geometry: LatLng(
                      _dadosTransporte[_id]['localAtual'].latitude,
                      _dadosTransporte[_id]['localAtual'].longitude
                  )
              )
          );
          print("Dado atualizado! ${_dadosTransporte[_id]}");
        }else if(dados.type == DocumentChangeType.removed){
          //Removido do firebase
          String _id = dados.doc.id;
          if(_symbolSelecionado == _symbolTransporte[_id]) _symbolSelecionado = null; //Caso eu esteja deletando o symbol selecionado
          await mapController.removeSymbol(_symbolTransporte[_id]);
          _dadosTransporte.remove(_id);
          _symbolTransporte.remove(_id);
          print("Dado removido! ${dados.doc.data()}");
        }
      });
    });
  }

  void getPermissaoLocalizacao() async{
    bool localAtivo;
    LocationPermission permissao;

    localAtivo = await Geolocator.isLocationServiceEnabled();
    if(!localAtivo){
      print("GPS Desativado!");
      showOkAlertDialog(context: context, title: "Atenção", message: "Seu GPS está desligado");
    }

    permissao = await Geolocator.checkPermission();
    if(permissao == LocationPermission.denied){

      permissao = await Geolocator.requestPermission();
      if(permissao == LocationPermission.deniedForever){
        print("Permissão Negada Permanentemente! O usuário tem que ir nas configurações para alterar...");
        permissaoLocal = false;
        showOkAlertDialog(context: context, title: "Atenção", message: "O Aplicativo precisa da permissão para funcionar corretamente, por favor entre nas configurações e dê a permissão!");
      }

      if(permissao == LocationPermission.denied){
        print("Permissão Negada!");
        permissaoLocal = false;
        showOkAlertDialog(context: context, title: "Atenção", message: "O Aplicativo precisa da permissão para funcionar corretamente, por favor entre nas configurações e dê a permissão!");
      }

    }else if(permissao == LocationPermission.always){
      print("Permissão para utilizar em segundo plano!");
      permissaoLocal = true;
      minhaLocalizacao(true);
    }else if(permissao == LocationPermission.whileInUse){
      print("Permissão para utilizar o GPS só quand o App está aberto!");
      permissaoLocal = true;
      minhaLocalizacao(true);
    }
  }

  void minhaLocalizacao(bool listen) async{
    try{
      if(listen){
        StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            intervalDuration: Duration(seconds: 5)//Tem que lembrar que o banco de dados é gratuito, ou seja, tem limite de requisição, por isso tem que restringir!
        ).listen((Position posicao) {
          if(_position == null){//teoricamente, só vai entrar na hora que abrir
            setState(() {
              _position = posicao;
              mapboxLocalizacao = true;
            });
            if(_busAtivo && _position != null && !_modoEspera) atualizarTransporte();//Caso esteja compartilhando a localização
            if(_busAtivo && _position != null && _modoEspera) criarTransporte();//Tentando sair do modo de espera
            if(_rotaAtiva && _rotaGerada != []) calculaTimePonto(_rotaGerada);//Atualiza o tempo até a parada de ônibus
          }else{
            _position = posicao;
            if(_position == null){//Caso ocorra uma falha, desativa a localização
              setState(() {
                mapboxLocalizacao = false;
              });
            }
            if(_busAtivo && _position != null && !_modoEspera) atualizarTransporte();//Caso esteja compartilhando a localização
            if(_busAtivo && _position != null && _modoEspera) criarTransporte();//Tentando sair do modo de espera
            if(_rotaAtiva && _rotaGerada != []) calculaTimePonto(_rotaGerada);//Atualiza o tempo até a parada de ônibus
          }
        });
        print(positionStream);
      }else{
        _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      }
    }catch(error){
      print(error);
    }
  }

  void centralizarPosicao(){
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_position.latitude, _position.longitude), zoom: 13)
      )
    );
  }

  void janelaTransporte(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text(_janelaTransporteTitulo),
          content: SingleChildScrollView(
            child: Form(
              key: _keyFormTransporte,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _tipoSelecionado,
                          items: [
                            DropdownMenuItem(
                              value: "bus",
                              child: Text("Ônibus"),
                            ),
                            DropdownMenuItem(
                              value: "taxi-lotacao",
                              child: Text("Táxi Lotação"),
                            ),
                            DropdownMenuItem(
                              value: "moto-taxi",
                              child: Text("Moto Táxi"),
                            ),
                          ],
                          onChanged: (valor){
                            setState(() {
                              _tipoSelecionado = valor;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  TextFormField(
                    controller: _destinoTransporte,
                    decoration: InputDecoration(
                        labelText: "Destino",
                        hintText: "Local onde irá descer do transporte"
                    ),
                    validator: (valor){
                      return Validador().add(Validar.OBRIGATORIO, msg: "Campo obrigatório").valido(valor);
                    },
                    maxLines: null,
                    maxLength: 200,
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.close),
                              label: Text(
                                  "Cancelar"
                              ),
                              onPressed: (){
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  primary: Colors.red
                              ),
                            ),
                          )
                      ),
                      Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.directions_bus),
                              label: Text(
                                  _btnJanelaTransporteConfirmar
                              ),
                              onPressed: (){
                                if(_keyFormTransporte.currentState.validate()){
                                  //Criar o transporte
                                  criarTransporte();
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  primary: _btnJanelaTransporteConfirmarCor
                              ),
                            ),
                          )
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        );
      }
    );
  }

  void janelaTransporteMapBox(String _id){//Janela que aparece ao clicar no icone
    Map<String, dynamic> dados = _dadosTransporte[_id];
    print(dados);
    String tipo = dados['tipo'];
    TextEditingController destino = TextEditingController();
    destino.text = dados['destino'];
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
              title: Text("Informações"),
              content: SingleChildScrollView(
                child: Form(
                  key: _keyFormTransporte,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              isDense: false,
                              value: tipo,
                              items: [
                                DropdownMenuItem(
                                  value: "bus",
                                  child: Text("Ônibus"),
                                ),
                                DropdownMenuItem(
                                  value: "taxi-lotacao",
                                  child: Text("Táxi Lotação"),
                                ),
                                DropdownMenuItem(
                                  value: "moto-taxi",
                                  child: Text("Moto Táxi"),
                                ),
                              ],
                              onChanged: null,
                            ),
                          )
                        ],
                      ),
                      TextFormField(
                        controller: destino,
                        enabled: false,
                        decoration: InputDecoration(
                            labelText: "Destino",
                            hintText: "Local onde irá descer do transporte"
                        ),
                        validator: (valor){
                          return Validador().add(Validar.OBRIGATORIO, msg: "Campo obrigatório").valido(valor);
                        },
                        maxLines: null,
                        maxLength: 200,
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.close),
                                  label: Text(
                                      "Fechar"
                                  ),
                                  onPressed: (){
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      primary: Colors.red
                                  ),
                                ),
                              )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
          );
        }
    );
  }

  void janelaPontoBus(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
              title: Text(_janelaPontoBusTitulo),
              content: SingleChildScrollView(
                child: Form(
                  key: _keyFormPontoBus,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nomePontoBus,
                        decoration: InputDecoration(
                            labelText: "Nome",
                            hintText: "Algo facil de lembrar"
                        ),
                        maxLines: null,
                        maxLength: 30,
                        validator: (valor){
                          return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                        },
                      ),
                      TextFormField(
                        controller: _descricaoPontoBus,
                        decoration: InputDecoration(
                            labelText: "Descrição",
                            hintText: "Algum ponto de referência"
                        ),
                        maxLines: null,
                        maxLength: 200,
                        validator: (valor){
                          return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.close),
                                  label: Text(
                                      "Cancelar"
                                  ),
                                  onPressed: (){
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      primary: Colors.red
                                  ),
                                ),
                              )
                          ),
                          Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.add_location_alt),
                                  label: Text(
                                      'Criar'
                                  ),
                                  onPressed: (){
                                    if(_keyFormPontoBus.currentState.validate()){
                                      //Criar ponto de ônibus
                                      criarPontoBus();
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      primary: Colors.green
                                  ),
                                ),
                              )
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
          );
        }
    );
  }

  void janelaPontoBusMapBox(String _id){//Janela que aparece ao clicar no icone
    Map<String, dynamic> dados = _dadosPontoBus[_id];
    TextEditingController nome = TextEditingController();
    nome.text = dados['nome'];
    TextEditingController descricao = TextEditingController();
    descricao.text = dados['descricao'];
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
              title: Text('Informações'),
              content: SingleChildScrollView(
                child: Form(
                  key: _keyFormPontoBus,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nome,
                        decoration: InputDecoration(
                            labelText: "Nome",
                            hintText: "Algo facil de lembrar"
                        ),
                        maxLines: null,
                        maxLength: 30,
                        validator: (valor){
                          return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                        },
                      ),
                      TextFormField(
                        controller: descricao,
                        decoration: InputDecoration(
                            labelText: "Descrição",
                            hintText: "Algum ponto de referência"
                        ),
                        maxLines: null,
                        maxLength: 200,
                        validator: (valor){
                          return Validador().add(Validar.OBRIGATORIO, msg: "Campo Obrigatório").valido(valor);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.restore_from_trash_sharp),
                                  label: Text(
                                      'Deletar'
                                  ),
                                  onPressed: (){
                                    if(_keyFormPontoBus.currentState.validate()){
                                      //Deletar ponto de ônibus
                                      if(symbolDentroRaio(_dadosPontoBus[_id]['localAtual'], 50)){//Só pode deletar o ponto, caso esteja próximo dele, ou seja, teoricamente você está confirmando que ele não existe
                                        deletarPontoBus(_id);
                                        Navigator.pop(context);
                                      }else{
                                        showOkAlertDialog(context: context, title: "Atenção", message: "Só pode deletar ponto de ônibus caso esteja próximo, dessa forma você pode confirmar que ele não existe!");
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      primary: Colors.amber
                                  ),
                                ),
                              )
                          ),
                          Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.add_location_alt),
                                  label: Text(
                                      'Salvar'
                                  ),
                                  onPressed: (){
                                    if(_keyFormPontoBus.currentState.validate()){
                                      //Salvar ponto de ônibus
                                      atualizarPontoBus(_id, nome.text, descricao.text);
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      primary: Colors.blue
                                  ),
                                ),
                              )
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
          );
        }
    );
  }

  String getNome(String tipo){
    switch(tipo){
      case "bus": return "Ônibus";
      case "taxi-lotacao": return "Táxi Lot.";
      case "moto-taxi": return "Moto Táxi";
      default: return "Erro";
    }
  }

  String getIcone(String tipo){
    switch(tipo){
      case "bus": return "bus-15";
      case "taxi-lotacao": return "car-15-maki";
      case "moto-taxi": return "moto-15";
      default: return "road-closure";
    }
  }

  void criarTransporte() {
    String _id = FirebaseAuth.instance.currentUser.uid;
    minhaLocalizacao(false);
    String _idBusProximo = symbolMaisProximo(_dadosTransporte);
    GeoPoint posicaoBus = (_idBusProximo != "") ? _dadosTransporte[_idBusProximo]['localAtual'] : GeoPoint(0, 0);//0,0 fica no meio do mar, não vai ter problema
    if(!symbolDentroRaio(posicaoBus, 10)){//Só cria o transporte caso não tenha nenhum a 10m, assim evita várias pessoas compartilhar o mesmo transporte
      Transporte transporte = Transporte(getNome(_tipoSelecionado), _tipoSelecionado, _destinoTransporte.text, GeoPoint(_position.latitude, _position.longitude));
      FirebaseFirestore firebase = FirebaseFirestore.instance;
      firebase.collection("Transporte").doc(_id).set(transporte.toMap()).then((value){
        print("Transporte Criado!");
        final snackBar = SnackBar(
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          content: Text(
              "Transporte criado!"
          ),
        );
        setState(() {
          apagarRota();//É sem sentido deixar a rota gerada quando já está no transporte, e rota é para encontrar o ponto para pegar o transporte...
          _busAtivo = true;
          _btnTransporte = Colors.green.withOpacity(0.7);
          _btnJanelaTransporteConfirmar = "Salvar";
          _btnJanelaTransporteConfirmarCor = Colors.blue;
        });
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }).catchError((error){
        print(error);
        final snackBar = SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          content: Text(
              "Ops... Houve um erro!"
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }else{//Entra em modo de espera, até sair
      print("Transporte entrou em modo de espera!");
      final snackBar = SnackBar(
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Você entrou em modo de espera!"
        ),
      );
      setState(() {
        _modoEspera = true;//Quando distanciar irá compartilhar automaticamente, quando ficar false
        _busAtivo = true;
        _btnTransporte = Colors.amber.withOpacity(0.7);
      });
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void atualizarTransporte() {
    String _id = FirebaseAuth.instance.currentUser.uid;
    minhaLocalizacao(false);
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("Transporte").doc(_id).update({
      "localAtual":GeoPoint(_position.latitude, _position.longitude),
      "ultimaAtualizacao":DateTime.now()
    }).then((value){
      print("Posição do transporte atualizado!");
    }).catchError((error){
      print(error);
    });
  }

  void deletarTransporte() {
    if(!_modoEspera){
      String _id = FirebaseAuth.instance.currentUser.uid;
      FirebaseFirestore firebase = FirebaseFirestore.instance;
      firebase.collection("Transporte").doc(_id).delete().then((value){
        print("Transporte Cancelado!");
        final snackBar = SnackBar(
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
          content: Text(
              "Transporte cancelado!"
          ),
        );
        setState(() {
          _busAtivo = false;
          _btnTransporte = Colors.grey.withOpacity(0.7);
          _btnJanelaTransporteConfirmar = "Criar";
          _btnJanelaTransporteConfirmarCor = Colors.green;
        });
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }).catchError((error){
        print(error);
        final snackBar = SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          content: Text(
              "Ops... Houve um erro!"
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }else{
      setState(() {
        _busAtivo = false;
        _modoEspera = false;
        _btnTransporte = Colors.grey.withOpacity(0.7);
      });
    }
  }

  void criarPontoBus() {
    minhaLocalizacao(false);
    PontoBus pontoBus = PontoBus(_nomePontoBus.text, _descricaoPontoBus.text, GeoPoint(_position.latitude, _position.longitude));
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("PontoBus").add(pontoBus.toMap()).then((value){
      print("Ponto Criado!");
      final snackBar = SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ponto criado!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }).catchError((error){
      print(error);
      final snackBar = SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ops... Houve um erro!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void atualizarPontoBus(String _id, nome, descricao) {
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("PontoBus").doc(_id).update({
      "nome":nome,
      "descricao":descricao,
      "ultimaAtualizacao":DateTime.now()
    }).then((value){
      print("Ponto Atualizado!");
      final snackBar = SnackBar(
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ponto Atualizado!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }).catchError((error){
      print(error);
      final snackBar = SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ops... Houve um erro!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void deletarPontoBus(String _id) {
    FirebaseFirestore firebase = FirebaseFirestore.instance;
    firebase.collection("PontoBus").doc(_id).delete().then((value){
      print("Ponto Cancelado!");
      final snackBar = SnackBar(
        backgroundColor: Colors.yellow,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ponto deletado!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }).catchError((error){
      print(error);
      final snackBar = SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(
            "Ops... Houve um erro!"
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  String symbolMaisProximo(Map<String, dynamic> listaDados) {
    minhaLocalizacao(false);
    Position minhaPosicao = _position;
    double distancia = double.infinity;
    String id = "";
    listaDados.forEach((_id, dado) {
      double novaDistacia = Geolocator.distanceBetween(minhaPosicao.latitude, minhaPosicao.longitude, dado['localAtual'].latitude, dado['localAtual'].longitude);
      if(distancia >= novaDistacia){
        distancia = novaDistacia;
        id = _id;
      }
    });
    return id;
  }

  bool symbolDentroRaio(GeoPoint symbolPosicao, double raio){
    minhaLocalizacao(false);
    Position minhaPosicao = _position;
    double distanciaSymbol = Geolocator.distanceBetween(minhaPosicao.latitude, minhaPosicao.longitude, symbolPosicao.latitude, symbolPosicao.longitude);
    if(distanciaSymbol <= raio){
      return true;
    }else{
      return false;
    }
  }

  void buscarPontoBus() async{
    try{
      minhaLocalizacao(false);
      GeoPoint minhaPosicao = GeoPoint(_position.latitude, _position.longitude);
      String idPontoBus = symbolMaisProximo(_dadosPontoBus);
      if(idPontoBus != ""){//Ou seja, encontrou uma ponto de bus
        GeoPoint symbolPosicao = _dadosPontoBus[idPontoBus]['localAtual'];
        //https://docs.mapbox.com/api/navigation/directions/#retrieve-directions
        //No link acima está as configurações possiveis para usar na requisição http
        String urlBase = 'https://api.mapbox.com/directions/v5/mapbox/walking/';
        const String access_token = 'pk.eyJ1IjoibXlidXNwcm9qZXRvIiwiYSI6ImNrOGk1bW50NzAyOTIzbXBqcnR4Njk2bGQifQ.fIxLWrS0pbmlErHwYSfjhw';
        String urlFinal = urlBase +
            minhaPosicao.longitude.toString() +
            ',' +
            minhaPosicao.latitude.toString() +
            ';' +
            symbolPosicao.longitude.toString() +
            ',' +
            symbolPosicao.latitude.toString() +
            '?steps=true' +
            '&access_token=' +
            access_token;
        print(urlFinal);
        var url = Uri.parse(urlFinal);
        var response = await http.get(url);
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        Map<String, dynamic> valor = jsonDecode(response.body);
        if (valor['code'] != "InvalidInput") {
          //Codigo de erro, quando não encontra rota
          List<dynamic> rotaJSON = valor['routes'][0]['legs'][0]['steps'];
          List<dynamic> rotaAUX = [];
          List<GeoPoint> pontosRota = [];
          for (int i = 0; i < rotaJSON.length; i++) {
            rotaAUX.add(rotaJSON[i]['intersections']);
          }
          for (int i = 0; i < rotaAUX.length; i++) {
            for (int j = 0; j < rotaAUX[i].length; j++) {
              GeoPoint aux = new GeoPoint(rotaAUX[i][j]['location'][1], rotaAUX[i][j]['location'][0]);
              pontosRota.add(aux);
            }
          }
          if(pontosRota.isNotEmpty){
            List<LatLng> rotaGeradaConvertida = [];
            for (int i = 0; i < pontosRota.length; i++) {
              LatLng auxPoint =
              new LatLng(pontosRota[i].latitude, pontosRota[i].longitude);
              rotaGeradaConvertida.add(auxPoint);
            }
            await mapController.addLine(
              LineOptions(
                geometry: rotaGeradaConvertida,
                lineColor: "#ff0000",
                lineWidth: 5.0,
                lineOpacity: 0.5,
              ),
            ).then((_){
              LatLng northeast;
              LatLng southwest;
              if (minhaPosicao.latitude <= symbolPosicao.latitude) {
                northeast = new LatLng(symbolPosicao.latitude, symbolPosicao.longitude);
                southwest = new LatLng(minhaPosicao.latitude, minhaPosicao.longitude);
              } else {
                northeast = new LatLng(minhaPosicao.latitude, minhaPosicao.longitude);
                southwest = new LatLng(symbolPosicao.latitude, symbolPosicao.longitude);
              }
              LatLngBounds zoomPontos = new LatLngBounds(
                northeast: northeast,
                southwest: southwest,
              );
              mapController
                  .animateCamera(
                CameraUpdate.newLatLngBounds(zoomPontos),
              );
              setState(() {
                _txtBtnBuscar = "Apagar Rota";
                _btnBuscar = Colors.red;
                _rotaAtiva = true;
                _rotaGerada = pontosRota;
              });
              calculaTimePonto(_rotaGerada);
            });
          }else{
            showOkAlertDialog(context: context, title: "Atenção", message: "Ocorreu um erro: Rota gerada é vazia!");
          }
        }else{
          showOkAlertDialog(context: context, title: "Atenção", message: "Não existe caminho até o ponto mais próximo!");
        }
      }else{
        showOkAlertDialog(context: context, title: "Atenção", message: "Não existe pontos de ônibus no mapa!");
      }
    }catch(error){
      print(error);
    }
  }

  void apagarRota(){
    mapController.clearLines();
    setState(() {
      _rotaAtiva = false;
      _txtBtnBuscar = "Buscar Ponto de Ônibus";
      _btnBuscar = Colors.blue;
      _txtTimeBus = "Eu → Ponto: ∞";
      _rotaGerada = [];
    });
  }

  void calculaTimePonto(List<GeoPoint> rota){
    minhaLocalizacao(false);
    Position _minhaPosicao = _position;
    double distanciaTotal = 0;
    int valorProximo = 0;
    double distanciaProxima = double.infinity;
    List<GeoPoint> novaRota = [];
    for(int i = 0; i < rota.length; i++){//Encontra o ponto mais proxima na rota gerada, desse modo eu posso retirar o restante que já passou
      double novaDistancia = Geolocator.distanceBetween(_minhaPosicao.latitude, _minhaPosicao.longitude, rota[i].latitude, rota[i].longitude);
      if(novaDistancia <= distanciaProxima){
        distanciaProxima = novaDistancia;
        valorProximo = i;
      }
    }
    if(valorProximo != 0){
      if((valorProximo + 1) < rota.length){//aqui é adicionado + 1, pois quando o usuario passar do ponto, este ponto ainda vai continuar mais perto do que o próximo
        for(int i = (valorProximo+1); i < rota.length; i++){
          novaRota.add(rota[i]);
        }
      }else{
        if((valorProximo + 1) == rota.length)//Significa que o ponto proximo é o ultimo
          novaRota.add(rota[valorProximo]);
        else
          print("Houve um erro ao calcular o tempo");
      }
    }else{
      novaRota = rota;
    }
    distanciaTotal += Geolocator.distanceBetween(_minhaPosicao.latitude, _minhaPosicao.longitude, novaRota[0].latitude, novaRota[0].longitude);//Distância do usuario até o ponto mais proximo, OBS: já foi feito o ajuste no array, descartando os pontos passados
    for(int i = 0; (i+1) < novaRota.length; i++){
      distanciaTotal += Geolocator.distanceBetween(novaRota[i].latitude, novaRota[i].longitude, novaRota[i+1].latitude, novaRota[i+1].longitude);
    }
    double velocidade = _minhaPosicao.speed;//Recebe em M/s, porém não funfa em todos os dispositivos, nesse caso aparece como 0
    if(velocidade < 0.3){//Pessoa está praticamente parada
      if(distanciaTotal >= 1000){
        distanciaTotal /= 1000;
        setState(() {
          _txtTimeBus = "Eu → Ponto: ${distanciaTotal.toStringAsFixed(1)} KM";
        });
      }else{
        setState(() {
          _txtTimeBus = "Eu → Ponto: ${distanciaTotal.toStringAsFixed(1)} metros";
        });
      }
    }else{
      //velocidade = espaço(m)/tempo(s)
      double tempo = distanciaTotal/velocidade;
      if(tempo <= 60){//Segundos
        setState(() {
          _txtTimeBus = "Eu → Ponto: ${tempo.toStringAsFixed(1)} Segundos";
        });
      }else if(tempo > 60 && tempo <= 3600){//Minutos
        tempo /= 60;
        setState(() {
          _txtTimeBus = "Eu → Ponto: ${tempo.toStringAsFixed(1)} Minutos";
        });
      }else{//Horas
        tempo /= 3600;
        setState(() {
          _txtTimeBus = "Eu → Ponto: ${tempo.toStringAsFixed(1)} Horas";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WikiBus"),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: (){
              Navigator.pushNamed(context, "info");
            },
          ),
          IconButton(
            icon: Icon(Icons.email_outlined),
            onPressed: (){
              Navigator.pushNamed(context, "feedback");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _txtTimeBus,
                    textAlign: TextAlign.center,
                  ),
                )
              ),
            ],
          ),
          Expanded(
            child: MapboxMap(
              accessToken: "pk.eyJ1IjoibXlidXNwcm9qZXRvIiwiYSI6ImNrOGk1bW50NzAyOTIzbXBqcnR4Njk2bGQifQ.fIxLWrS0pbmlErHwYSfjhw",
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0)),
              onStyleLoadedCallback: _onStyleLoadedCallback,
              styleString: "mapbox://styles/mybusprojeto/cklsrgqne1qoo17qlj57b6fwv",
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              myLocationEnabled: mapboxLocalizacao,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  child: Text(
                      _txtBtnBuscar,
                      style: TextStyle(
                        fontSize: 17
                      ),
                  ),
                  onPressed: (){
                    //Buscar o ponto mais proximo
                    (_rotaAtiva) ? apagarRota() : buscarPontoBus();
                  },
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                      primary: _btnBuscar,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: FloatingActionButton(
              heroTag: "fabLocal",
              child: Icon(Icons.my_location),
              backgroundColor: Colors.blue.withOpacity(0.7),
              onPressed: (){
                centralizarPosicao();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: FloatingActionButton(
              heroTag: "fabPonto",
              child: Icon(Icons.add_location_alt),
              backgroundColor: Colors.yellow.withOpacity(0.7),
              onPressed: (){
                janelaPontoBus();
              },
            ),
          ),
          if (_busAtivo)//Só aparece caso o compartilhamento esteja ativo
            Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: FloatingActionButton(
                heroTag: "fabCancelar",
                child: Icon(Icons.close),
                backgroundColor: Colors.red.withOpacity(0.7),
                mini: true,
                onPressed: (){
                  deletarTransporte();
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: 55),
            child: FloatingActionButton(
              heroTag: "fabTransporte",
              child: Icon(Icons.directions_bus),
              backgroundColor: _btnTransporte,
              onPressed: (){
                janelaTransporte();
              },
            ),
          )
        ],
      )
    );
  }
}
