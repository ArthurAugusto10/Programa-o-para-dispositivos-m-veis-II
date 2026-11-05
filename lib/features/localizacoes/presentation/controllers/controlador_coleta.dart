
import 'package:flutter/material.dart';

import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';

class ControladorColeta extends ChangeNotifier {
  final ServicoLocalizacao _servico;

  ControladorColeta({
    ServicoLocalizacao? servico,
  }) : _servico = servico ?? ServicoLocalizacao();

  bool _coletando = false;
  bool _iniciando = false;

  Localizacao? _ultimaLocalizacao;

  String? _erro;
  String? _mensagem;

  bool get coletando => _coletando;
  bool get iniciando => _iniciando;

  Localizacao? get ultimaLocalizacao => _ultimaLocalizacao;

  String? get erro => _erro;
  String? get mensagem => _mensagem;

  // Inicia a coleta contínua.
  Future<void> iniciar() async {
    if (_coletando || _iniciando) {
      return;
    }

    _iniciando = true;
    _erro = null;
    _mensagem = null;

    notifyListeners();

    try {
      await _servico.iniciarColeta(
        onLocalizacao: (localizacao) {
          _ultimaLocalizacao = localizacao;
          _mensagem = 'Localização recebida e salva.';

          notifyListeners();
        },
        onErro: (erro) {
          _erro = erro.toString();

          notifyListeners();
        },
      );

      _coletando = _servico.coletando;

      if (_coletando) {
        _mensagem = 'Coleta iniciada. Aguardando localização...';
      }
    } catch (erro) {
      _erro = erro.toString();
      _coletando = false;
    } finally {
      _iniciando = false;
      notifyListeners();
    }
  }

  // Interrompe a coleta.
  Future<void> parar() async {
    try {
      await _servico.pararColeta();

      _coletando = false;
      _mensagem = 'Coleta interrompida.';
      _erro = null;
    } catch (erro) {
      _erro = erro.toString();
    }

    notifyListeners();
  }

  // Libera os recursos quando o controlador deixa de ser utilizado.
  @override
  void dispose() {
    _servico.pararColeta();
    super.dispose();
  }
}
