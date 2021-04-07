import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:validadores/Validador.dart';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  //Mapa
  MapboxMapController mapController;
  bool mapboxLocalizacao = false;

  //Geral
  String _txtBtnBuscar = "Buscar Ponto de Ônibus";
  String _txtTimeBus = "Eu → Ponto: ∞";
  Color _btnBuscar = Colors.blue;
  Color _btnTransporte = Colors.grey.withOpacity(0.7);
  bool _busAtivo = false;

  //Usuário
  bool permissaoLocal;
  Position _position;

  //Transporte
  String _janelaTransporteTitulo = "Criar Transporte";
  String _btnJanelaTransporteConfirmar = "Criar";
  final _keyFormTransporte = GlobalKey<FormState>();
  String _tipoSelecionado = "bus";

  //PontoBus
  String _janelaPontoBusTitulo = "Criar Ponto";
  String _btnJanelaPontoBusConfirmar = "Criar";
  final _keyFormPontoBus = GlobalKey<FormState>();

  @override
  void initState(){
    getPermissaoLocalizacao();
    super.initState();
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void onStyleLoadedCallback() {
    print("Mapa carregado!");
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
    if(listen){
      StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: 5)
      ).listen((Position posicao) {
        if(_position == null){//teoricamente, só vai entrar na hora que abrir
          setState(() {
            _position = posicao;
            mapboxLocalizacao = true;
          });
        }else{
          _position = posicao;
          if(_position == null){//Caso ocorra uma falha, desativa a localização
            setState(() {
              mapboxLocalizacao = false;
            });
          }
        }
      });
      print(positionStream);
    }else{
      _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
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
                    decoration: InputDecoration(
                        labelText: "Destino",
                        hintText: "Local onde irá descer do transporte"
                    ),
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
                                //Criar o transporte
                                setState(() {
                                  _busAtivo = true;
                                  _btnTransporte = Colors.green.withOpacity(0.7);
                                });
                                Navigator.pop(context);
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
                                      _btnJanelaPontoBusConfirmar
                                  ),
                                  onPressed: (){
                                    if(_keyFormPontoBus.currentState.validate()){
                                      //Criar ponto de ônibus
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
              onStyleLoadedCallback: onStyleLoadedCallback,
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
                  setState(() {
                    _busAtivo = false;
                    _btnTransporte = Colors.grey.withOpacity(0.7);
                  });
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
