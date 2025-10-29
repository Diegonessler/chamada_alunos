import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/aluno.dart';
import '../utils/rodada_simulador.dart';
import '../utils/rede_util.dart';
import 'package:permission_handler/permission_handler.dart';

class PresencaScreen extends StatefulWidget {
  const PresencaScreen({Key? key}) : super(key: key);

  @override
  _PresencaScreenState createState() => _PresencaScreenState();
}

class _PresencaScreenState extends State<PresencaScreen> {
  Aluno? aluno;
  bool carregando = true;

  int get rodadaAtual => RodadaSimulador.getRodadaAtual();

  String get dataHoje {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  Future<void> inicializar() async {
    await RodadaSimulador.restaurarCiclo(onUpdate: () {
      if (mounted) setState(() {});
    });
    await solicitarPermissaoLocalizacao();
    await carregarAluno();
    if (mounted) setState(() => carregando = false);
  }

  Future<void> solicitarPermissaoLocalizacao() async {
    final status = await Permission.location.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de localização é necessária para validar presença'),
        ),
      );
    }
  }

  Future<void> carregarAluno() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('matricula') ?? '000';
    final nome = prefs.getString('nome') ?? 'Aluno';
    final json = prefs.getString('presenca_$id');

    if (!mounted) return;

    setState(() {
      aluno = json != null
          ? Aluno.fromJson(jsonDecode(json))
          : Aluno(id: id, nome: nome);
    });
  }

  Future<void> salvarAluno() async {
    final prefs = await SharedPreferences.getInstance();
    if (aluno != null) {
      prefs.setString('presenca_${aluno!.id}', jsonEncode(aluno!.toJson()));
    }
  }

  void registrarPresenca() async {
    final conectado = await estaNaRedeDaEscola();
    final rodada = rodadaAtual;
    final data = dataHoje;
    final chavePresenca = '${RodadaSimulador.cicloAtual}-$data-$rodada';

    if (!mounted) return;

    if (rodada <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma rodada em andamento')),
      );
      return;
    }

    if (!conectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não está na rede da escola')),
      );
      return;
    }

    if (aluno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados do aluno')),
      );
      return;
    }

    final jaRegistrado = aluno!.presencasRegistradas.contains(chavePresenca);
    final podeAlterar = RodadaSimulador.podeAlterarPresencaRodada(rodada);

    if (jaRegistrado || !podeAlterar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Presença já registrada ou rodada encerrada')),
      );
      return;
    }

    setState(() {
      aluno!.presencasRegistradas.add(chavePresenca);
    });

    await salvarAluno();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Presença registrada na rodada $rodada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando || aluno == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rodada = rodadaAtual;
    final data = dataHoje;
    final chavePresenca = '${RodadaSimulador.cicloAtual}-$data-$rodada';
    final jaRegistrado = aluno!.presencasRegistradas.contains(chavePresenca);
    final podeAlterar = RodadaSimulador.podeAlterarPresencaRodada(rodada);

    final status = rodada > 0
        ? (jaRegistrado ? 'Presente' : 'Ausente')
        : 'Sem rodada';

    return Scaffold(
      appBar: AppBar(title: Text('Presença - Rodada $rodada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Olá, ${aluno!.nome}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text('Status da rodada: $status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (rodada == 0 || jaRegistrado || !podeAlterar)
                  ? null
                  : registrarPresenca,
              child: Text(
                jaRegistrado
                    ? 'Presença já registrada'
                    : rodada == 0
                        ? 'Aguardando rodada...'
                        : 'Registrar presença na rodada $rodada',
              ),
            ),
          ],
        ),
      ),
    );
  }
}