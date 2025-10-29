import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RodadaSimulador {
  static List<Rodada> rodadas = [];
  static int cicloAtual = DateTime.now().millisecondsSinceEpoch;
  static DateTime? dataEncerramento;
  static bool forcarReinicioHoje = false; // ✅ flag de teste

  static Future<void> iniciarSimulacao(VoidCallback onUpdate) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Bloqueia reinício se já foi encerrado hoje (exceto em modo teste)
    final dataString = prefs.getString('dataEncerramento');
    if (dataString != null && !forcarReinicioHoje) {
      final encerrado = DateTime.tryParse(dataString);
      final hoje = DateTime.now();
      final mesmoDia = encerrado != null &&
          hoje.year == encerrado.year &&
          hoje.month == encerrado.month &&
          hoje.day == encerrado.day;

      if (mesmoDia) return;
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

    for (int i = 0; i < rodadas.length; i++) {
      Future.delayed(Duration(seconds: i * 5), () async {
        rodadas[i].estado = 'Em andamento';
        await _salvarRodadas();
        onUpdate();

        Future.delayed(Duration(seconds: 4), () async {
          rodadas[i].estado = 'Encerrada';
          await _salvarRodadas();
          onUpdate();

          if (rodadas.every((r) => r.estado == 'Encerrada')) {
            dataEncerramento = DateTime.now();
            await prefs.setString(
              'dataEncerramento',
              dataEncerramento!.toIso8601String(),
            );
          }
        });
      });
    }
  }

  static Future<void> restaurarCiclo({VoidCallback? onUpdate}) async {
    final prefs = await SharedPreferences.getInstance();
    cicloAtual = prefs.getInt('cicloAtual') ?? DateTime.now().millisecondsSinceEpoch;

    final json = prefs.getString('rodadas');
    if (json != null) {
      final lista = jsonDecode(json) as List;
      rodadas = lista.map((r) => Rodada.fromJson(r)).toList();
    }

    final dataString = prefs.getString('dataEncerramento');
    if (dataString != null) {
      dataEncerramento = DateTime.tryParse(dataString);

      final hoje = DateTime.now();
      final encerrado = dataEncerramento!;
      final mesmoDia = hoje.year == encerrado.year &&
          hoje.month == encerrado.month &&
          hoje.day == encerrado.day;

      if (!mesmoDia) {
        resetarSimulacao();
        await iniciarSimulacao(onUpdate ?? () {});
      }
    } else {
      await iniciarSimulacao(onUpdate ?? () {});
    }
  }

  static void resetarSimulacao() {
    rodadas.clear();
    dataEncerramento = null;
  }

  static Future<void> liberarRodadaHojeManualmente(VoidCallback onUpdate) async {
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
      orElse: () => Rodada(numero: 0, estado: 'Nenhuma', presenca: 'Nenhuma'),
    );

    return rodada.estado == 'Em andamento' && !rodada.presencaRegistrada;
  }

  static Future<void> alterarPresenca(int numeroRodada, String novaPresenca) async {
    final rodada = rodadas.firstWhere((r) => r.numero == numeroRodada);

    if (!podeAlterarPresencaRodada(numeroRodada)) {
      throw Exception('Presença já registrada ou rodada encerrada.');
    }

    if (novaPresenca.trim().isEmpty || novaPresenca == 'Pendente') {
      throw Exception('Presença inválida.');
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