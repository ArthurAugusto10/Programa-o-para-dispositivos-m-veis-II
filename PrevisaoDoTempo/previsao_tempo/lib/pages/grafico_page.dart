import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/previsao.dart';

class GraficoPage extends StatelessWidget {
  final PrevisaoCidade previsao;

  const GraficoPage({
    super.key,
    required this.previsao,
  });

  @override
  Widget build(BuildContext context) {
    final dias = previsao.dias;

    final temperaturas = <double>[
      for (final dia in dias) ...[
        if (dia.minima != null) dia.minima!,
        if (dia.maxima != null) dia.maxima!,
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de temperaturas'),
      ),
      body: SafeArea(
        child: temperaturas.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não há temperaturas disponíveis para gerar o gráfico.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _conteudo(context, dias, temperaturas),
      ),
    );
  }

  Widget _conteudo(
    BuildContext context,
    List<PrevisaoDia> dias,
    List<double> temperaturas,
  ) {
    final valoresOrdenados = [...temperaturas]..sort();

    final minY =
        (valoresOrdenados.first / 5).floorToDouble() * 5 - 5;
    final maxY =
        (valoresOrdenados.last / 5).ceilToDouble() * 5 + 5;
    final intervaloY = ((maxY - minY) / 5).ceilToDouble();

    final minimas = <FlSpot>[];
    final maximas = <FlSpot>[];

    for (var i = 0; i < dias.length; i++) {
      final dia = dias[i];

      minimas.add(
        dia.minima == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), dia.minima!),
      );

      maximas.add(
        dia.maxima == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), dia.maxima!),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          previsao.cidade.nomeCompleto,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Temperaturas previstas em graus Celsius (°C).'),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _Legenda(cor: Colors.blue, texto: 'Mínima'),
            _Legenda(cor: Colors.red, texto: 'Máxima'),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: dias.length == 1 ? -0.5 : 0,
                  maxX: dias.length == 1
                      ? 0.5
                      : (dias.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: intervaloY,
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
                        reservedSize: 44,
                        interval: intervaloY,
                        getTitlesWidget: (valor, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${valor.toStringAsFixed(0)}°',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (valor, meta) {
                          final indice = valor.round();

                          if ((valor - indice).abs() > 0.001 ||
                              indice < 0 ||
                              indice >= dias.length) {
                            return const SizedBox.shrink();
                          }

                          final data = dias[indice].data;

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              data == null
                                  ? 'Dia ${indice + 1}'
                                  : DateFormat('dd/MM').format(data),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    if (dias.any((dia) => dia.minima != null))
                      LineChartBarData(
                        spots: minimas,
                        color: Colors.blue,
                        barWidth: 3,
                        isCurved: false,
                        dotData: const FlDotData(show: true),
                      ),
                    if (dias.any((dia) => dia.maxima != null))
                      LineChartBarData(
                        spots: maximas,
                        color: Colors.red,
                        barWidth: 3,
                        isCurved: false,
                        dotData: const FlDotData(show: true),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Valores por dia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < dias.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              dias[i].data == null
                  ? 'Dia ${i + 1}: data não informada'
                  : DateFormat('dd/MM/yyyy').format(dias[i].data!),
            ),
            subtitle: Text(
              'Mínima: ${_temperatura(dias[i].minima)}'
              '  |  Máxima: ${_temperatura(dias[i].maxima)}',
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Valores ausentes não são representados no gráfico.\n'
          'Fonte dos dados: CPTEC/INPE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  String _temperatura(double? valor) {
    return valor == null
        ? 'não informada'
        : '${NumberFormat('0.#', 'pt_BR').format(valor)} °C';
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const _Legenda({
    required this.cor,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.show_chart, color: cor),
        const SizedBox(width: 6),
        Text(texto),
      ],
    );
  }
}