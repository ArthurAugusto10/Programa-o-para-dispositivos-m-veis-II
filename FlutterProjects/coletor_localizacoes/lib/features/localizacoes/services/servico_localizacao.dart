
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Verifica se o serviço de localização está habilitado.
  Future<bool> verificarServicoHabilitado() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Verifica e solicita a permissão de localização.
  Future<bool> verificarPermissao() async {
    LocationPermission permissao =
        await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    return permissao != LocationPermission.denied &&
        permissao != LocationPermission.deniedForever;
  }

  // Prepara as permissões necessárias.
  Future<void> prepararLocalizacao() async {
    final servicoHabilitado =
        await verificarServicoHabilitado();

    if (!servicoHabilitado) {
      throw Exception(
        'O serviço de localização está desabilitado.',
      );
    }

    final permissaoConcedida =
        await verificarPermissao();

    if (!permissaoConcedida) {
      throw Exception(
        'Permissão de localização não concedida.',
      );
    }

    // A permissão de notificações é específica do Android.
    if (!kIsWeb && Platform.isAndroid) {
      final notificacao =
          await Permission.notification.request();

      if (!notificacao.isGranted) {
        throw Exception(
          'Permissão de notificações não concedida.',
        );
      }
    }
  }

  // Obtém uma localização pontual.
  Future<Localizacao> obterPosicaoAtual() async {
    await prepararLocalizacao();

    final Position posicao =
        await Geolocator.getCurrentPosition(
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

  // Inicia a coleta contínua.
  Future<void> iniciarColeta({
    void Function(Localizacao localizacao)? onLocalizacao,
    void Function(Object erro)? onErro,
  }) async {
    if (coletando || _iniciando) {
      return;
    }

    _iniciando = true;

    try {
      await prepararLocalizacao();

      // Configuração compatível com Web e outras plataformas.
      LocationSettings configuracoes = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      // No Android, utiliza a notificação de primeiro plano.
      if (!kIsWeb && Platform.isAndroid) {
        configuracoes = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 20),
          foregroundNotificationConfig:
              const ForegroundNotificationConfig(
            notificationTitle: 'Coletor de Localizações',
            notificationText:
                'Sua localização está sendo coletada.',
            enableWakeLock: true,
          ),
        );
      }

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

          onLocalizacao?.call(localizacao);

          // Mantém as gravações organizadas.
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

  // Interrompe a coleta e aguarda gravações pendentes.
  Future<void> pararColeta() async {
    final assinatura = _assinatura;

    _assinatura = null;

    if (assinatura != null) {
      await assinatura.cancel();
    }

    await _filaGravacao;
  }
}
