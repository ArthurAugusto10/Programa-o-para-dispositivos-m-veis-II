
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final RepositorioLocalizacoes _repositorio =
      RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarLocalizacoes();
  }

  Future<void> _carregarLocalizacoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _repositorio.buscarUltimas();

      if (!mounted) return;

      setState(() {
        _localizacoes = resultado;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = erro.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  List<Marker> _criarMarcadores() {
    return _localizacoes.asMap().entries.map((entrada) {
      final indice = entrada.key;
      final localizacao = entrada.value;

      // O primeiro registro é o mais recente.
      final maisRecente = indice == 0;

      return Marker(
        point: LatLng(
          localizacao.latitude,
          localizacao.longitude,
        ),
        width: 48,
        height: 48,
        child: Tooltip(
          message:
              'Latitude: ${localizacao.latitude}\n'
              'Longitude: ${localizacao.longitude}\n'
              'Data: ${localizacao.instante.toLocal()}',
          child: Icon(
            Icons.location_on,
            size: maisRecente ? 44 : 32,
            color: maisRecente ? Colors.red : Colors.blue,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar mapa',
            onPressed: _carregando ? null : _carregarLocalizacoes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Text('Erro: $_erro'),
                )
              : _localizacoes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma localização para exibir no mapa.',
                      ),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _localizacoes.first.latitude,
                          _localizacoes.first.longitude,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
  urlTemplate:
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName:
      'com.example.coletor_localizacoes',
  tileProvider: NetworkTileProvider(),
),
                        MarkerLayer(
                          markers: _criarMarcadores(),
                        ),
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),
    );
  }
}
