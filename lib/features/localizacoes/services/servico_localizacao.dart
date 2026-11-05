
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/localizacao.dart';
import '../data/repositories/repositorio_localizacoes.dart';

class ServicoLocalizacao {
  final RepositorioLocalizacoes _repositorio;

  ServicoLocalizacao({
    RepositorioLocalizacoes? repositorio,
  }) : _repositorio = repositorio ?? RepositorioLocalizacoes();

  StreamSubscription<Position>? _assinatura;

  Future<void> _filaGravacao = Future<void>.value();

  bool _iniciando = false;

  bool get coletando => _assinatura != null;

  // Verifica se o serviço de localização do aparelho está habilitado.
  Future<bool> verificarServicoHabilitado() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Verifica e solicita a permissão de localização.
  Future<bool> verificarPermissao() async {
    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Verifica se o GPS está habilitado e se a permissão foi concedida.
  Future<void> prepararLocalizacao() async {
    final servicoHabilitado = await verificarServicoHabilitado();

    if (!servicoHabilitado) {
      throw Exception(
        'O serviço de localização está desabilitado. Ative o GPS.',
      );
    }

    final permissaoConcedida = await verificarPermissao();

    if (!permissaoConcedida) {
      throw Exception('Permissão de localização não concedida.');
    }
  }

  // Obtém uma localização pontual.
  Future<Localizacao> obterPosicaoAtual() async {
    await prepararLocalizacao();

    final Position posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp,
    );
  }

  // Inicia a coleta contínua de localizações.
  Future<void> iniciarColeta({
    void Function(Localizacao localizacao)? onLocalizacao,
    void Function(Object erro)? onErro,
  }) async {
    // Evita criar assinaturas duplicadas.
    if (coletando || _iniciando) {
      return;
    }

    _iniciando = true;

    try {
      await prepararLocalizacao();

      final configuracoes = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 20),
      );

      _assinatura = Geolocator.getPositionStream(
        locationSettings: configuracoes,
      ).listen(
        (Position posicao) {
          final localizacao = Localizacao(
            latitude: posicao.latitude,
            longitude: posicao.longitude,
            precisao: posicao.accuracy,
            instante: posicao.timestamp,
          );

          // Envia a posição recebida para o controlador da tela.
          onLocalizacao?.call(localizacao);

          // Organiza as gravações para evitar operações simultâneas.
          _filaGravacao = _filaGravacao.then((_) async {
            try {
              await _repositorio.salvar(localizacao);
            } catch (erro) {
              onErro?.call(erro);
            }
          });
        },
        onError: (Object erro) {
          onErro?.call(erro);
        },
        onDone: () {
          _assinatura = null;
        },
      );
    } catch (erro) {
      onErro?.call(erro);
      rethrow;
    } finally {
      _iniciando = false;
    }
  }

  // Cancela a coleta e aguarda as gravações pendentes.
  Future<void> pararColeta() async {
    final assinatura = _assinatura;

    if (assinatura == null) {
      return;
    }

    _assinatura = null;

    await assinatura.cancel();
    await _filaGravacao;
  }
}
