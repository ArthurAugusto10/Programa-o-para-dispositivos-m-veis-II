import 'package:flutter/material.dart';
import 'previsao_page.dart';
import '../models/cidade.dart';
import '../services/cptec_service.dart';
import '../services/armazenamento_service.dart';
import 'favoritos_page.dart';

class PesquisaPage extends StatefulWidget {
  const PesquisaPage({super.key});

  @override
  State<PesquisaPage> createState() => _PesquisaPageState();
}

class _PesquisaPageState extends State<PesquisaPage> {
  final _controller = TextEditingController();
  final _service = CptecService();
  final _armazenamento = ArmazenamentoService();
  bool _salvandoFavorita = false;
  List<Cidade> _cidades = [];
  bool _carregando = false;
  String? _mensagem;

  Future<void> _pesquisar() async {
    if (_carregando) return;

    final nome = _controller.text.trim();

    if (nome.isEmpty) {
      setState(() {
        _mensagem = 'Digite o nome de uma cidade.';
        _cidades = [];
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _mensagem = null;
      _cidades = [];
    });

    try {
      final cidades = await _service.buscarCidades(nome);

      if (!mounted) return;

      setState(() {
        _cidades = cidades;

        if (cidades.isEmpty) {
          _mensagem = 'Nenhuma cidade encontrada. '
              'Tente outro nome.';
        }
      });
    } on CptecException catch (erro) {
      if (!mounted) return;

      setState(() {
        _mensagem = erro.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _mensagem = 'Não foi possível realizar a pesquisa. '
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

  void _selecionarCidade(Cidade cidade) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PrevisaoPage(cidade: cidade),
    ),
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvarFavorita(Cidade cidade) async {
  if (_salvandoFavorita) return;

  setState(() {
    _salvandoFavorita = true;
  });

  try {
    await _armazenamento.salvarFavorita(cidade);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cidade.nomeCompleto} salva nos favoritos!'),
      ),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível salvar a cidade.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _salvandoFavorita = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Previsão do Tempo'),
  centerTitle: true,
  actions: [
    IconButton(
      tooltip: 'Cidades favoritas',
      onPressed: _salvandoFavorita
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const FavoritosPage(),
                ),
              );
            },
      icon: const Icon(Icons.star),
    ),
  ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                'Como estará o tempo?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesquise uma cidade brasileira para começar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                enabled: !_carregando,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _pesquisar(),
                decoration: const InputDecoration(
                  labelText: 'Nome da cidade',
                  hintText: 'Ex.: Jacareí',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _carregando ? null : _pesquisar,
                icon: const Icon(Icons.search),
                label: const Text('Pesquisar'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _construirResultados(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fonte dos dados: CPTEC/INPE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirResultados() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mensagem != null) {
      return Center(
        child: SingleChildScrollView(
          child: Text(
            _mensagem!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_cidades.isEmpty) {
      return const Center(
        child: Text(
          'Os resultados da pesquisa aparecerão aqui.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _cidades.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cidade = _cidades[index];

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(cidade.nome),
            subtitle: Text(
              cidade.uf.isEmpty ? 'UF não informada' : cidade.uf,
            ),
            trailing: IconButton(
  tooltip: 'Salvar nos favoritos',
  onPressed: _salvandoFavorita
      ? null
      : () => _salvarFavorita(cidade),
  icon: const Icon(Icons.star_border),
),
            onTap: () => _selecionarCidade(cidade),
          ),
        );
      },
    );
  }
}