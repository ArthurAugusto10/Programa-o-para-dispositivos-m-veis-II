import 'package:flutter/material.dart';

import 'features/localizacoes/services/servico_localizacao.dart';
import 'features/localizacoes/models/localizacao.dart';

class MeuAplicativo extends StatelessWidget {
  const MeuAplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coletor de Localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final ServicoLocalizacao _servico = ServicoLocalizacao();

  Localizacao? _localizacao;
  String? _erro;
  bool _carregando = false;

  Future<void> testarLocalizacao() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _localizacao = null;
    });

    try {
      final resultado = await _servico.obterPosicaoAtual();

      if (!mounted) return;

      setState(() {
        _localizacao = resultado;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de localização'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _carregando ? null : testarLocalizacao,
                icon: const Icon(Icons.location_on),
                label: const Text('Obter localização atual'),
              ),
              const SizedBox(height: 24),

              if (_carregando)
                const CircularProgressIndicator(),

              if (_localizacao != null) ...[
                Text('Latitude: ${_localizacao!.latitude}'),
                Text('Longitude: ${_localizacao!.longitude}'),
                Text('Precisão: ${_localizacao!.precisao} metros'),
                Text('Data: ${_localizacao!.instante}'),
              ],

              if (_erro != null)
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}