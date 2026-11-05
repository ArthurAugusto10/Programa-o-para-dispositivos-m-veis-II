
import 'package:flutter/material.dart';
import 'features/localizacoes/services/servico_localizacao.dart';
import 'features/localizacoes/models/localizacao.dart';
import 'features/localizacoes/presentation/controllers/controlador_coleta.dart';
import 'features/localizacoes/presentation/screens/tela_historico.dart';
import 'features/localizacoes/presentation/screens/tela_mapa.dart';

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
  final ControladorColeta _controlador = ControladorColeta();

  Localizacao? _localizacao;
  String? _erro;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();

    // Atualiza a tela quando o controlador recebe dados.
    _controlador.addListener(_atualizarTela);
  }

  void _atualizarTela() {
    if (mounted) {
      setState(() {});
    }
  }

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
  void dispose() {
    _controlador.removeListener(_atualizarTela);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultimaLocalizacao =
        _controlador.ultimaLocalizacao ?? _localizacao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletor de Localizações'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 64,
                color: Colors.blue,
              ),

              const SizedBox(height: 16),

              const Text(
                'Coleta de Localizações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Obtém uma localização pontual.
              ElevatedButton.icon(
                onPressed:
                    _carregando ? null : testarLocalizacao,
                icon: const Icon(Icons.my_location),
                label: const Text('Obter localização atual'),
              ),

              const SizedBox(height: 16),

              // Inicia a coleta contínua.
              ElevatedButton.icon(
                onPressed: _controlador.coletando ||
                        _controlador.iniciando
                    ? null
                    : _controlador.iniciar,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar coleta contínua'),
              ),

              const SizedBox(height: 12),

              // Interrompe a coleta contínua.
              OutlinedButton.icon(
                onPressed: _controlador.coletando
                    ? _controlador.parar
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Parar coleta'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                 Navigator.push(
                  context,
                 MaterialPageRoute(
                    builder: (context) => const TelaHistorico(),
                 ),
               );
             },
             icon: const Icon(Icons.history),
             label: const Text('Ver histórico'),
            ),

            const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                 Navigator.push(
                  context,
                 MaterialPageRoute(
                    builder: (context) => const TelaMapa(),
                  ),
                );
             },
             icon: const Icon(Icons.map),
             label: const Text('Ver mapa'),
           ),

              const SizedBox(height: 24),

              if (_carregando || _controlador.iniciando)
                const CircularProgressIndicator(),

              const SizedBox(height: 16),

              Text(
                _controlador.coletando
                    ? 'Status: coletando localizações'
                    : 'Status: coleta parada',
                style: TextStyle(
                  color: _controlador.coletando
                      ? Colors.green
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Exibe a última localização recebida.
              if (ultimaLocalizacao != null) ...[
                const Text(
                  'Última localização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Latitude: ${ultimaLocalizacao.latitude}',
                ),
                Text(
                  'Longitude: ${ultimaLocalizacao.longitude}',
                ),
                Text(
                  'Precisão: ${ultimaLocalizacao.precisao} metros',
                ),
                Text(
                  'Data: ${ultimaLocalizacao.instante}',
                ),
              ],

              if (_controlador.mensagem != null) ...[
                const SizedBox(height: 16),
                Text(
                  _controlador.mensagem!,
                  textAlign: TextAlign.center,
                ),
              ],

              if (_erro != null || _controlador.erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erro ?? _controlador.erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
