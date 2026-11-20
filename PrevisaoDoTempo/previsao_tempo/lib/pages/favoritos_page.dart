import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../services/armazenamento_service.dart';
import 'previsao_page.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _armazenamento = ArmazenamentoService();

  List<Cidade> _cidades = [];
  bool _carregando = true;
  bool _removendo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final cidades = await _armazenamento.buscarFavoritas();

      if (!mounted) return;

      setState(() {
        _cidades = cidades;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar as cidades favoritas.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _remover(Cidade cidade) async {
    if (_removendo) return;

    setState(() {
      _removendo = true;
    });

    try {
      await _armazenamento.removerFavorita(cidade.id);

      if (!mounted) return;

      setState(() {
        _cidades.removeWhere((item) => item.id == cidade.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cidade.nomeCompleto} removida dos favoritos.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível remover a cidade.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _removendo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cidades favoritas'),
      ),
      body: SafeArea(
        child: _conteudo(),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cidades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma cidade favorita.\n'
            'Volte à pesquisa e toque na estrela para salvar uma cidade.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cidades.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cidade = _cidades[index];

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            title: Text(cidade.nomeCompleto),
            subtitle: const Text('Toque para consultar a previsão'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => PrevisaoPage(cidade: cidade),
                ),
              );
            },
            trailing: IconButton(
              tooltip: 'Remover dos favoritos',
              onPressed: _removendo ? null : () => _remover(cidade),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }
}