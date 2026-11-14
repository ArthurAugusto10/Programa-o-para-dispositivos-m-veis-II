import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/abastecimento.dart';
import '../repositories/abastecimento_repository.dart';

class AbastecimentoPage extends StatefulWidget {
  final int veiculoId;

  const AbastecimentoPage({
    super.key,
    required this.veiculoId,
  });

  @override
  State<AbastecimentoPage> createState() => _AbastecimentoPageState();
}

class _AbastecimentoPageState extends State<AbastecimentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _precoController = TextEditingController();
  final _kmController = TextEditingController();
  final _litrosController = TextEditingController();
  final _repository = AbastecimentoRepository();

  final _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  TipoCombustivel _combustivel = TipoCombustivel.gasolina;
  DateTime _dataHora = DateTime.now();
  bool _salvando = false;

  double? _numero(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  double get _total {
    final preco = _numero(_precoController.text) ?? 0;
    final litros = _numero(_litrosController.text) ?? 0;
    final total = preco * litros;

    return total.isFinite && total >= 0 ? total : 0;
  }

  @override
  void dispose() {
    _precoController.dispose();
    _kmController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  String? _validarPositivo(String? texto) {
    final valor = _numero(texto ?? '');

    if (valor == null || !valor.isFinite || valor <= 0) {
      return 'Informe um valor maior que zero.';
    }

    return null;
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(1900),
      lastDate: agora,
    );

    if (!mounted || data == null) return;

    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );

    if (!mounted || horario == null) return;

    final selecionada = DateTime(
      data.year,
      data.month,
      data.day,
      horario.hour,
      horario.minute,
    );

    if (selecionada.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O abastecimento não pode estar no futuro.'),
        ),
      );
      return;
    }

    setState(() {
      _dataHora = selecionada;
    });
  }

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    final abastecimento = Abastecimento(
      veiculoId: widget.veiculoId,
      combustivel: _combustivel,
      precoLitro: _numero(_precoController.text)!,
      quilometragem: _numero(_kmController.text)!,
      litros: _numero(_litrosController.text)!,
      dataHora: _dataHora,
    );

    setState(() {
      _salvando = true;
    });

    try {
      await _repository.cadastrar(abastecimento);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;

      final mensagem = erro.toString().replaceFirst(
        RegExp(r'^(Exception|Bad state|Invalid argument\(s\)): '),
        '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Novo abastecimento'),
          automaticallyImplyLeading: !_salvando,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Considere o tanque completo em cada registro.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<TipoCombustivel>(
                  initialValue: _combustivel,
                  decoration: const InputDecoration(
                    labelText: 'Combustível',
                  ),
                  items: TipoCombustivel.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.descricao),
                    );
                  }).toList(),
                  onChanged: _salvando
                      ? null
                      : (tipo) {
                          if (tipo == null) return;
                          setState(() {
                            _combustivel = tipo;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precoController,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço por litro (R\$)',
                    hintText: 'Ex.: 6,00',
                  ),
                  validator: _validarPositivo,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _kmController,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem (km)',
                    hintText: 'Ex.: 10000',
                    helperText: 'Digite sem separador de milhares.',
                  ),
                  validator: (texto) {
                    final valor = _numero(texto ?? '');

                    if (valor == null || !valor.isFinite || valor < 0) {
                      return 'Informe uma quilometragem válida.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _litrosController,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de litros',
                    hintText: 'Ex.: 32,5',
                  ),
                  validator: _validarPositivo,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Data e horário'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(_dataHora),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _salvando ? null : _selecionarDataHora,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Valor total'),
                        const SizedBox(height: 8),
                        Text(
                          _moeda.format(_total),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _salvando ? 'Salvando...' : 'Salvar abastecimento',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}