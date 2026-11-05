
import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final RepositorioLocalizacoes _repositorio =
      RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
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

  Future<void> _confirmarLimpeza() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'Todas as localizações armazenadas serão excluídas. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    try {
      await _repositorio.limpar();

      if (!mounted) return;

      await _carregarHistorico();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Histórico apagado com sucesso.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao limpar histórico: $erro'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar histórico',
            onPressed: _carregando ? null : _carregarHistorico,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando || _localizacoes.isEmpty
                ? null
                : _confirmarLimpeza,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _localizacoes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma localização armazenada.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _localizacoes.length,
                      itemBuilder: (context, index) {
                        final localizacao = _localizacoes[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(
                              'Latitude: ${localizacao.latitude}\n'
                              'Longitude: ${localizacao.longitude}',
                            ),
                            subtitle: Text(
                              'Precisão: ${localizacao.precisao} m\n'
                              'Data: ${localizacao.instante.toLocal()}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
