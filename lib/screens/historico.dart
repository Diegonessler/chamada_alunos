import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/aluno.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({Key? key}) : super(key: key);

  @override
  _HistoricoScreenState createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  Aluno? aluno;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('matricula') ?? '000';
    final json = prefs.getString('presenca_$id');
    if (json != null) {
      final alunoCarregado = Aluno.fromJson(jsonDecode(json));
      setState(() {
        aluno = alunoCarregado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(aluno != null ? 'Histórico de ${aluno!.nome}' : 'Histórico'),
      ),
      body: aluno == null
          ? const Center(child: CircularProgressIndicator())
          : _buildHistorico(),
    );
  }

  Widget _buildHistorico() {
    final agrupadoPorData = <String, Map<int, String>>{};

    for (final chave in aluno!.presencasRegistradas) {
      final partes = chave.split('-');
      if (partes.length == 5) {
        final data = '${partes[1]}-${partes[2]}-${partes[3]}';
        final rodada = int.tryParse(partes[4]) ?? 0;

        if (rodada >= 1 && rodada <= 4) {
          agrupadoPorData.putIfAbsent(data, () => {});
          agrupadoPorData[data]![rodada] = 'Presente';
        }
      }
    }

    for (final data in agrupadoPorData.keys) {
      for (int i = 1; i <= 4; i++) {
        agrupadoPorData[data]!.putIfAbsent(i, () => 'Ausente');
      }
    }

    if (agrupadoPorData.isEmpty) {
      return const Center(child: Text('Nenhuma presença registrada'));
    }

    return ListView(
      children: agrupadoPorData.entries.map((entry) {
        final data = entry.key;
        final rodadas = entry.value;
        return ExpansionTile(
          title: Text('Dia $data'),
          children: rodadas.entries.map((r) {
            return ListTile(
              leading: CircleAvatar(child: Text('${r.key}')),
              title: Text('Rodada ${r.key}'),
              subtitle: Text('Status: ${r.value}'),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
