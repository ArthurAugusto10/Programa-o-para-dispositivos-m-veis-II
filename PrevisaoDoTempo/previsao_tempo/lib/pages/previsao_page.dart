import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'grafico_page.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/cptec_service.dart';
import '../widgets/previsao_card.dart';

class PrevisaoPage extends StatefulWidget {
  final Cidade cidade;

  const PrevisaoPage({
    super.key,
    required this.cidade,
  });

  @override
  State<PrevisaoPage> createState() => _PrevisaoPageState();
}

class _PrevisaoPageState extends State<PrevisaoPage> {
  final _service = CptecService();

  PrevisaoCidade? _previsao;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPrevisao();
  }

  Future<void> _carregarPrevisao() async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _service.buscarPrevisao(widget.cidade);

      if (!mounted) return;

      setState(() {
        _previsao = resultado;
      });
    } on CptecException catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = erro.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar a previsão. '
            'Tente novamente.';
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
        title: Text(widget.cidade.nomeCompleto),
        actions: [
          IconButton(
            tooltip: 'Atualizar previsão',
            onPressed: _carregando ? null : _carregarPrevisao,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_carregando) const LinearProgressIndicator(),
            Expanded(child: _conteudo()),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Fonte dos dados: CPTEC/INPE',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final previsao = _previsao;

    if (previsao == null) {
      if (_carregando) {
        return const Center(
          child: Text('Consultando previsão...'),
        );
      }

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro ?? 'Nenhuma previsão disponível.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregarPrevisao,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final atualizacao = previsao.atualizacao;

    return RefreshIndicator(
      onRefresh: _carregarPrevisao,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_erro != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Não foi possível atualizar: $_erro\n'
                  'Exibindo a previsão carregada anteriormente.',
                ),
              ),
            ),
          Text(
            atualizacao == null
                ? 'Atualização não informada'
                : 'Atualização: ${DateFormat('dd/MM/yyyy').format(atualizacao)}',
          ),
          const SizedBox(height: 16),
FilledButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GraficoPage(previsao: previsao),
      ),
    );
  },
  icon: const Icon(Icons.show_chart),
  label: const Text('Ver gráfico de temperaturas'),
),
const SizedBox(height: 16),
for (final dia in previsao.dias)
  PrevisaoCard(previsao: dia),
        ],
      ),
    );
  }
}