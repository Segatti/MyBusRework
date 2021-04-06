import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

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
                setState(() {
                  _busAtivo = true;
                  _btnTransporte = Colors.green.withOpacity(0.7);
                });
              },
            ),
          )
        ],
      )
    );
  }
}
