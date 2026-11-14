import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/abastecimento.dart';
import '../repositories/abastecimento_repository.dart';

class HistoricoPage extends StatefulWidget {
  final int veiculoId;

  const HistoricoPage({
    super.key,
    required this.veiculoId,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final _repository = AbastecimentoRepository();

  final _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final _numero = NumberFormat('#,##0.00', 'pt_BR');
  final _data = DateFormat('dd/MM/yyyy HH:mm');

  late Future<List<Abastecimento>> _consulta;

  @override
  void initState() {
    super.initState();
    _consulta = _repository.listar(widget.veiculoId);
  }

  void _recarregar() {
    setState(() {
      _consulta = _repository.listar(widget.veiculoId);
    });
  }

  Widget _criarCard(
    Abastecimento atual,
    Abastecimento? anterior,
    int numero,
  ) {
    final consumo = anterior == null
        ? null
        : atual.consumoDesde(anterior);

    final custoKm = anterior == null
        ? null
        : atual.custoPorKmDesde(anterior);

    final distancia = anterior == null
        ? null
        : atual.distanciaDesde(anterior);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abastecimento $numero',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(_data.format(atual.dataHora)),
            const Divider(height: 24),
            Text('Combustível: ${atual.combustivel.descricao}'),
            Text(
              'Quilometragem: ${_numero.format(atual.quilometragem)} km',
            ),
            Text('Quantidade: ${_numero.format(atual.litros)} L'),
            Text('Preço por litro: ${_moeda.format(atual.precoLitro)}'),
            const SizedBox(height: 8),
            Text(
              'Total: ${_moeda.format(atual.valorTotal)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            if (anterior == null)
              const Text(
                'Referência inicial: o consumo e o custo por km '
                'serão calculados a partir do próximo abastecimento.',
              )
            else if (consumo == null || custoKm == null)
              const Text(
                'Não foi possível calcular os indicadores deste intervalo.',
              )
            else ...[
              Text(
                'Distância percorrida: ${_numero.format(distancia)} km',
              ),
              Text('Consumo: ${_numero.format(consumo)} km/L'),
              Text('Custo por km: ${_moeda.format(custoKm)}/km'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de abastecimentos'),
        actions: [
          IconButton(
            onPressed: _recarregar,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Abastecimento>>(
          future: _consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Não foi possível carregar o histórico.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _recarregar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final registros = snapshot.data ?? [];

            if (registros.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhum abastecimento registrado.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // A consulta vem em ordem crescente.
            // A tela mostra os mais recentes primeiro,
            // preservando o registro anterior para os cálculos.
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: registros.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final posicao = registros.length - 1 - index;
                final atual = registros[posicao];
                final anterior = posicao > 0
                    ? registros[posicao - 1]
                    : null;

                return _criarCard(
                  atual,
                  anterior,
                  posicao + 1,
                );
              },
            );
          },
        ),
      ),
    );
  }
}