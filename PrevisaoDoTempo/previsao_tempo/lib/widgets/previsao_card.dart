import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/previsao.dart';

class PrevisaoCard extends StatelessWidget {
  final PrevisaoDia previsao;

  const PrevisaoCard({
    super.key,
    required this.previsao,
  });

  static const _descricoes = {
    'ec': 'Encoberto com chuvas isoladas',
    'ci': 'Chuvas isoladas',
    'c': 'Chuva',
    'in': 'Instável',
    'pp': 'Possibilidade de pancadas de chuva',
    'cm': 'Chuva pela manhã',
    'cn': 'Chuva à noite',
    'pt': 'Pancadas de chuva à tarde',
    'pm': 'Pancadas de chuva pela manhã',
    'np': 'Nublado e pancadas de chuva',
    'pc': 'Pancadas de chuva',
    'pn': 'Parcialmente nublado',
    'cv': 'Chuvisco',
    'ch': 'Chuvoso',
    't': 'Tempestade',
    'ps': 'Predomínio de sol',
    'e': 'Encoberto',
    'n': 'Nublado',
    'cl': 'Céu claro',
    'nv': 'Nevoeiro',
    'g': 'Geada',
    'ne': 'Neve',
    'nd': 'Condição não definida',
    'pnt': 'Pancadas de chuva à noite',
    'psc': 'Possibilidade de chuva',
    'pcm': 'Possibilidade de chuva pela manhã',
    'pct': 'Possibilidade de chuva à tarde',
    'pcn': 'Possibilidade de chuva à noite',
    'npt': 'Nublado com pancadas à tarde',
    'npn': 'Nublado com pancadas à noite',
    'ncn': 'Nublado com possibilidade de chuva à noite',
    'nct': 'Nublado com possibilidade de chuva à tarde',
    'ncm': 'Nublado com possibilidade de chuva pela manhã',
    'npm': 'Nublado com pancadas pela manhã',
    'npp': 'Nublado com possibilidade de chuva',
    'vn': 'Variação de nebulosidade',
    'ct': 'Chuva à tarde',
    'ppn': 'Possibilidade de pancadas de chuva à noite',
    'ppt': 'Possibilidade de pancadas de chuva à tarde',
    'ppm': 'Possibilidade de pancadas de chuva pela manhã',
  };

  IconData _icone(String codigo) {
    if (codigo == 'cl' || codigo == 'ps') {
      return Icons.wb_sunny;
    }

    if (codigo == 't') {
      return Icons.thunderstorm;
    }

    if (codigo == 'g' || codigo == 'ne') {
      return Icons.ac_unit;
    }

    if (codigo == 'nv') {
      return Icons.foggy;
    }

    if (codigo == 'pn' || codigo == 'vn') {
      return Icons.wb_cloudy;
    }

    if (codigo == 'n' || codigo == 'e' || codigo == 'in') {
      return Icons.cloud;
    }

    if (_descricoes.containsKey(codigo) && codigo != 'nd') {
      return Icons.water_drop;
    }

    return Icons.help_outline;
  }

  String _temperatura(double? valor) {
    return valor == null
        ? 'Não informada'
        : '${NumberFormat('0.#', 'pt_BR').format(valor)} °C';
  }

  @override
  Widget build(BuildContext context) {
    final data = previsao.data;
    final descricao = _descricoes[previsao.codigoTempo] ??
        'Condição não informada';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data == null
                  ? 'Data não informada'
                  : DateFormat('dd/MM/yyyy').format(data),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _icone(previsao.codigoTempo),
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(descricao)),
              ],
            ),
            const Divider(height: 24),
            Text('Mínima: ${_temperatura(previsao.minima)}'),
            const SizedBox(height: 6),
            Text('Máxima: ${_temperatura(previsao.maxima)}'),
            const SizedBox(height: 6),
            Text(
              previsao.indiceUv == null
                  ? 'Índice UV: não informado'
                  : 'Índice UV: ${NumberFormat('0.#', 'pt_BR').format(previsao.indiceUv)}',
            ),
          ],
        ),
      ),
    );
  }
}