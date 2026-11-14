import 'package:flutter/material.dart';
import 'abastecimento_page.dart';
import '../models/veiculo.dart';
import '../repositories/veiculo_repository.dart';
import 'cadastro_veiculo_page.dart';
import 'historico_page.dart';
import 'dashboard_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final _repository = VeiculoRepository();

  Veiculo? _veiculo;
  bool _carregando = true;
  bool _excluindo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarVeiculo();
  }

  String _mensagemErro(Object erro) {
    return erro.toString().replaceFirst(
      RegExp(r'^(Exception|Bad state|Invalid argument\(s\)): '),
      '',
    );
  }

  Future<void> _carregarVeiculo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final veiculo = await _repository.buscar();

      if (!mounted) return;

      setState(() {
        _veiculo = veiculo;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(erro);
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _abrirCadastro() async {
    final cadastrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CadastroVeiculoPage(),
      ),
    );

    if (!mounted || cadastrado != true) return;

    await _carregarVeiculo();
  }

  Future<void> _excluirVeiculo() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir veículo?'),
          content: const Text(
            'O veículo e todos os seus abastecimentos serão '
            'apagados permanentemente. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() {
      _excluindo = true;
    });

    try {
      await _repository.excluir();

      if (!mounted) return;

      setState(() {
        _veiculo = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo e abastecimentos excluídos.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(erro))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindo = false;
        });
      }
    }
  }

  Future<void> _abrirAbastecimento() async {
  final veiculoId = _veiculo?.id;
  if (veiculoId == null) return;

  final salvo = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => AbastecimentoPage(
        veiculoId: veiculoId,
      ),
    ),
  );

  if (!mounted || salvo != true) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Abastecimento registrado com sucesso.'),
    ),
  );
}

  Future<void> _abrirHistorico() async {
  final veiculoId = _veiculo?.id;
  if (veiculoId == null) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => HistoricoPage(
        veiculoId: veiculoId,
      ),
    ),
  );
}

  Future<void> _abrirDashboard() async {
  final veiculoId = _veiculo?.id;
  if (veiculoId == null) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DashboardPage(
        veiculoId: veiculoId,
      ),
    ),
  );
}

  Widget _conteudo() {
    if (_carregando || _excluindo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não foi possível carregar o veículo.\n$_erro',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregarVeiculo,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final veiculo = _veiculo;

    if (veiculo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_car_outlined,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'Cadastre seu veículo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Comece cadastrando o veículo para acompanhar '
                'seus abastecimentos e gastos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _abrirCadastro,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar veículo'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Meu veículo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 48,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  veiculo.marca,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(veiculo.modelo),
                const SizedBox(height: 12),
                Text('Ano: ${veiculo.ano}'),
                Text(
                  'Cilindrada: '
                  '${veiculo.cilindrada.toStringAsFixed(0)} cm³',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
  onPressed: _abrirAbastecimento,
  icon: const Icon(Icons.local_gas_station),
  label: const Text('Novo abastecimento'),
),

OutlinedButton.icon(
  onPressed: _abrirDashboard,
  icon: const Icon(Icons.bar_chart),
  label: const Text('Dashboard'),
),
const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: _abrirHistorico,
  icon: const Icon(Icons.history),
  label: const Text('Histórico de abastecimentos'),
),
const SizedBox(height: 12),

const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _excluirVeiculo,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir veículo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_excluindo,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle de combustível'),
        ),
        body: SafeArea(child: _conteudo()),
      ),
    );
  }
}