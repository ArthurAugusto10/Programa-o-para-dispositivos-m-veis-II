import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/abastecimento.dart';
import '../repositories/abastecimento_repository.dart';

class DashboardPage extends StatefulWidget {
  final int veiculoId;

  const DashboardPage({
    super.key,
    required this.veiculoId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repository = AbastecimentoRepository();

  final _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final _numero = NumberFormat('0.00', 'pt_BR');
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

  Widget _indicador(String titulo, String valor) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }

  Widget _grafico({
    required String titulo,
    required List<FlSpot> pontos,
    required Color cor,
    required String unidade,
  }) {
    if (pontos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '$titulo\n\nRegistre pelo menos dois abastecimentos '
            'para calcular este indicador.',
          ),
        ),
      );
    }

    final maior = pontos.fold<double>(
      0,
      (valor, ponto) => ponto.y > valor ? ponto.y : valor,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Eixo horizontal: número do abastecimento em ordem '
              'cronológica. Toque nos pontos para ver os valores.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: pontos.first.x - 0.5,
                  maxX: pontos.last.x + 0.5,
                  minY: 0,
                  maxY: maior > 0 ? maior * 1.2 : 1,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (valor, meta) {
                          return Text(
                            _numero.format(valor),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: pontos.length > 6
                            ? (pontos.length / 6).ceilToDouble()
                            : 1,
                        getTitlesWidget: (valor, meta) {
                          if (valor != valor.roundToDouble() ||
                              valor < pontos.first.x ||
                              valor > pontos.last.x) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${valor.toInt()}'),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (pontosTocados) {
                        return pontosTocados.map((ponto) {
                          return LineTooltipItem(
                            'Abast. ${ponto.x.toInt()}\n'
                            '${_numero.format(ponto.y)} $unidade',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: pontos,
                      isCurved: false,
                      color: cor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _montarDashboard(List<Abastecimento> registros) {
    final valores = <FlSpot>[];
    final consumos = <FlSpot>[];
    final custos = <FlSpot>[];

    double totalGasto = 0;

    for (var i = 0; i < registros.length; i++) {
      final atual = registros[i];
      final numero = (i + 1).toDouble();

      totalGasto += atual.valorTotal;
      valores.add(FlSpot(numero, atual.valorTotal));

      if (i == 0) continue;

      final anterior = registros[i - 1];
      final consumo = atual.consumoDesde(anterior);
      final custo = atual.custoPorKmDesde(anterior);

      if (consumo != null && consumo.isFinite) {
        consumos.add(FlSpot(numero, consumo));
      }

      if (custo != null && custo.isFinite) {
        custos.add(FlSpot(numero, custo));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _indicador('Total gasto', _moeda.format(totalGasto)),
        _indicador(
          'Abastecimentos registrados',
          '${registros.length}',
        ),
        if (consumos.isNotEmpty)
          _indicador(
            'Consumo do último intervalo válido',
            '${_numero.format(consumos.last.y)} km/L',
          ),
        if (custos.isNotEmpty)
          _indicador(
            'Custo do último intervalo válido',
            '${_moeda.format(custos.last.y)}/km',
          ),
        const SizedBox(height: 16),
        _grafico(
          titulo: 'Valor por abastecimento (R\$)',
          pontos: valores,
          cor: Colors.blue,
          unidade: 'R\$',
        ),
        const SizedBox(height: 12),
        _grafico(
          titulo: 'Evolução do consumo (km/L)',
          pontos: consumos,
          cor: Colors.teal,
          unidade: 'km/L',
        ),
        const SizedBox(height: 12),
        _grafico(
          titulo: 'Evolução do custo por km (R\$/km)',
          pontos: custos,
          cor: Colors.deepOrange,
          unidade: 'R\$/km',
        ),
        const SizedBox(height: 16),
        const Text(
          'O primeiro abastecimento é a referência inicial e não '
          'participa dos gráficos de consumo e custo por km.',
        ),
        const SizedBox(height: 20),
        Text(
          'Referência dos abastecimentos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...registros.asMap().entries.map((item) {
          return Text(
            '${item.key + 1} — ${_data.format(item.value.dataHora)}',
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Não foi possível carregar os indicadores.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _recarregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final registros = snapshot.data ?? [];

            if (registros.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Registre um abastecimento para começar '
                    'a acompanhar seus gastos.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return _montarDashboard(registros);
          },
        ),
      ),
    );
  }
}