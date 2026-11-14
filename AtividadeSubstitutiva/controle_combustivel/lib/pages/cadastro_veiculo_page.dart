import 'package:flutter/material.dart';

import '../models/opcao_veiculo.dart';
import '../models/veiculo.dart';
import '../repositories/veiculo_repository.dart';
import '../services/api_veiculos.dart';

class CadastroVeiculoPage extends StatefulWidget {
  const CadastroVeiculoPage({super.key});

  @override
  State<CadastroVeiculoPage> createState() => _CadastroVeiculoPageState();
}

class _CadastroVeiculoPageState extends State<CadastroVeiculoPage> {
  final _formKey = GlobalKey<FormState>();
  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  final _api = ApiVeiculos();
  final _repository = VeiculoRepository();

  List<OpcaoVeiculo> _marcas = [];
  List<OpcaoVeiculo> _modelos = [];

  String? _codigoMarca;
  String? _codigoModelo;
  String? _erroMarcas;
  String? _erroModelos;

  bool _carregandoMarcas = true;
  bool _carregandoModelos = false;
  bool _salvando = false;

  int _consultaModelos = 0;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  @override
  void dispose() {
    _anoController.dispose();
    _cilindradaController.dispose();
    super.dispose();
  }

  String _mensagemErro(Object erro) {
    return erro.toString().replaceFirst(
      RegExp(r'^(Exception|Bad state|Invalid argument\(s\)): '),
      '',
    );
  }

  Future<void> _carregarMarcas() async {
    setState(() {
      _carregandoMarcas = true;
      _erroMarcas = null;
    });

    try {
      final marcas = await _api.buscarMarcas();

      if (!mounted) return;

      setState(() {
        _marcas = marcas;
        if (marcas.isEmpty) {
          _erroMarcas = 'Nenhuma marca encontrada.';
        }
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erroMarcas = _mensagemErro(erro);
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregandoMarcas = false;
        });
      }
    }
  }

  Future<void> _carregarModelos(String codigoMarca) async {
    final consulta = ++_consultaModelos;

    setState(() {
      _codigoMarca = codigoMarca;
      _codigoModelo = null;
      _modelos = [];
      _erroModelos = null;
      _carregandoModelos = true;
    });

    try {
      final modelos = await _api.buscarModelos(codigoMarca);

      // Ignora respostas antigas se o usuário trocar de marca.
      if (!mounted || consulta != _consultaModelos) return;

      setState(() {
        _modelos = modelos;
        if (modelos.isEmpty) {
          _erroModelos = 'Nenhum modelo encontrado para essa marca.';
        }
      });
    } catch (erro) {
      if (!mounted || consulta != _consultaModelos) return;

      setState(() {
        _erroModelos = _mensagemErro(erro);
      });
    } finally {
      if (mounted && consulta == _consultaModelos) {
        setState(() {
          _carregandoModelos = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    final marca = _marcas.firstWhere(
      (item) => item.codigo == _codigoMarca,
    );
    final modelo = _modelos.firstWhere(
      (item) => item.codigo == _codigoModelo,
    );

    final veiculo = Veiculo(
      marca: marca.nome,
      modelo: modelo.nome,
      ano: int.parse(_anoController.text.trim()),
      cilindrada: double.parse(
        _cilindradaController.text.trim().replaceAll(',', '.'),
      ),
    );

    setState(() {
      _salvando = true;
    });

    try {
      await _repository.cadastrar(veiculo);

      if (!mounted) return;

      // A tela que abriu o cadastro receberá true para atualizar os dados.
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(erro))),
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
          title: const Text('Cadastrar veículo'),
          automaticallyImplyLeading: !_salvando,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 64,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dados do veículo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione a marca e o modelo. Depois, informe '
                  'o ano e a cilindrada em cm³.',
                ),
                const SizedBox(height: 24),
                if (_carregandoMarcas)
                  const LinearProgressIndicator()
                else if (_erroMarcas != null) ...[
                  Text(_erroMarcas!),
                  TextButton.icon(
                    onPressed: _carregarMarcas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar carregar marcas novamente'),
                  ),
                ] else
                  DropdownButtonFormField<String>(
                    initialValue: _codigoMarca,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    items: _marcas.map((marca) {
                      return DropdownMenuItem(
                        value: marca.codigo,
                        child: Text(
                          marca.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _salvando
                        ? null
                        : (codigo) {
                            if (codigo != null) {
                              _carregarModelos(codigo);
                            }
                          },
                    validator: (valor) {
                      return valor == null ? 'Selecione a marca.' : null;
                    },
                  ),
                const SizedBox(height: 16),
                if (_carregandoModelos)
                  const LinearProgressIndicator()
                else if (_erroModelos != null) ...[
                  Text(_erroModelos!),
                  TextButton.icon(
                    onPressed: () => _carregarModelos(_codigoMarca!),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar carregar modelos novamente'),
                  ),
                ] else
                  DropdownButtonFormField<String>(
                    key: ValueKey(_codigoMarca),
                    initialValue: _codigoModelo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'Selecione primeiro uma marca',
                      border: OutlineInputBorder(),
                    ),
                    items: _modelos.map((modelo) {
                      return DropdownMenuItem(
                        value: modelo.codigo,
                        child: Text(
                          modelo.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _salvando || _codigoMarca == null
                        ? null
                        : (codigo) {
                            setState(() {
                              _codigoModelo = codigo;
                            });
                          },
                    validator: (valor) {
                      return valor == null ? 'Selecione o modelo.' : null;
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _anoController,
                  enabled: !_salvando,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ano',
                    hintText: 'Ex.: 2020',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final ano = int.tryParse(valor?.trim() ?? '');
                    final limite = DateTime.now().year + 1;

                    if (ano == null || ano < 1886 || ano > limite) {
                      return 'Informe um ano entre 1886 e $limite.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cilindradaController,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cilindrada (cm³)',
                    hintText: 'Ex.: 1000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final cilindrada = double.tryParse(
                      (valor ?? '').trim().replaceAll(',', '.'),
                    );

                    if (cilindrada == null ||
                        !cilindrada.isFinite ||
                        cilindrada <= 0) {
                      return 'Informe uma cilindrada maior que zero.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _salvando ||
                          _carregandoMarcas ||
                          _carregandoModelos ||
                          _codigoMarca == null ||
                          _codigoModelo == null ||
                          _erroMarcas != null ||
                          _erroModelos != null
                      ? null
                      : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _salvando ? 'Salvando...' : 'Cadastrar veículo',
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