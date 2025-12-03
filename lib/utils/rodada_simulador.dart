import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RodadaSimulador {
  static List<Rodada> rodadas = [];
  static int cicloAtual = DateTime.now().millisecondsSinceEpoch;
  static DateTime? dataEncerramento;
  static bool forcarReinicioHoje = false;

  // ⏱️ CONFIGURAÇÃO DOS TEMPOS (SIMULAÇÃO RÁPIDA)
  static const int tempoRodada = 25; // em andamento (segundos)
  static const int tempoEncerramento = 10; // pausa entre rodadas

  static Future<void> iniciarSimulacao(VoidCallback onUpdate) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 Salvar início do dia (para não reiniciar quando reabrir app)
    prefs.setString('inicioDia', DateTime.now().toIso8601String());

    final dataString = prefs.getString('dataEncerramento');
    if (dataString != null && !forcarReinicioHoje) {
      final encerrado = DateTime.tryParse(dataString);
      final hoje = DateTime.now();

      if (_mesmoDia(hoje, encerrado!)) return;
    }

    cicloAtual = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('cicloAtual', cicloAtual);

    rodadas = List.generate(
      4,
      (i) => Rodada(
        numero: i + 1,
        estado: 'A iniciar',
        presenca: 'Pendente',
        presencaRegistrada: false,
      ),
    );
    await _salvarRodadas();

    // ⏳ Início do ciclo de rodadas
    for (int i = 0; i < rodadas.length; i++) {
      Future.delayed(Duration(seconds: i * (tempoRodada + tempoEncerramento)),
          () async {
        // INICIAR A RODADA
        rodadas[i].estado = 'Em andamento';
        await _salvarRodadas();
        onUpdate();

        // ENCERRAR APÓS O TEMPO
        Future.delayed(Duration(seconds: tempoRodada), () async {
          rodadas[i].estado = 'Encerrada';
          await _salvarRodadas();
          onUpdate();

          // TODAS ENCERRADAS → salva fim do dia
          if (rodadas.every((r) => r.estado == 'Encerrada')) {
            dataEncerramento = DateTime.now();
            prefs.setString(
                'dataEncerramento', dataEncerramento!.toIso8601String());
          }
        });
      });
    }
  }

  static Future<void> restaurarCiclo({VoidCallback? onUpdate}) async {
    final prefs = await SharedPreferences.getInstance();

    cicloAtual =
        prefs.getInt('cicloAtual') ?? DateTime.now().millisecondsSinceEpoch;

    final json = prefs.getString('rodadas');
    if (json != null) {
      rodadas = (jsonDecode(json) as List)
          .map((r) => Rodada.fromJson(r))
          .toList();
    }

    // 🔥 Se já iniciou hoje → NÃO reiniciar
    final inicioString = prefs.getString("inicioDia");

    if (inicioString != null) {
      final inicioDia = DateTime.parse(inicioString);

      if (_mesmoDia(DateTime.now(), inicioDia)) {
        return; // 🚀 NÃO reinicia, continua de onde parou
      }
    }

    // 🔄 Novo dia → inicia simulação
    await iniciarSimulacao(onUpdate ?? () {});
  }

  static bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static void resetarSimulacao() {
    rodadas.clear();
    dataEncerramento = null;
  }

  static Future<void> liberarRodadaHojeManualmente(
      VoidCallback onUpdate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dataEncerramento');
    dataEncerramento = null;
    forcarReinicioHoje = true;
    await iniciarSimulacao(onUpdate);
    forcarReinicioHoje = false;
  }

  static int getRodadaAtual() {
    final atual = rodadas.firstWhere(
      (r) => r.estado == 'Em andamento',
      orElse: () => Rodada(numero: 0, estado: 'Nenhuma', presenca: 'Nenhuma'),
    );
    return atual.numero;
  }

  static Future<void> _salvarRodadas() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(rodadas.map((r) => r.toJson()).toList());
    await prefs.setString('rodadas', json);
  }

  static bool podeAlterarPresencaRodada(int numeroRodada) {
    final rodada = rodadas.firstWhere(
      (r) => r.numero == numeroRodada,
      orElse: () =>
          Rodada(numero: 0, estado: 'Nenhuma', presenca: 'Nenhuma'),
    );

    return rodada.estado == 'Em andamento' && !rodada.presencaRegistrada;
  }

  static Future<void> alterarPresenca(
      int numeroRodada, String novaPresenca) async {
    final rodada = rodadas.firstWhere((r) => r.numero == numeroRodada);

    if (!podeAlterarPresencaRodada(numeroRodada)) {
      throw Exception('Presença já registrada ou rodada encerrada.');
    }

    rodada.presenca = novaPresenca;
    rodada.presencaRegistrada = true;
    await _salvarRodadas();
  }
}

class Rodada {
  final int numero;
  String estado;
  String presenca;
  bool presencaRegistrada;

  Rodada({
    required this.numero,
    required this.estado,
    this.presenca = 'Pendente',
    this.presencaRegistrada = false,
  });

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'estado': estado,
        'presenca': presenca,
        'presencaRegistrada': presencaRegistrada,
      };

  factory Rodada.fromJson(Map<String, dynamic> json) => Rodada(
        numero: json['numero'],
        estado: json['estado'],
        presenca: json['presenca'] ?? 'Pendente',
        presencaRegistrada: json['presencaRegistrada'] ?? false,
      );
}
