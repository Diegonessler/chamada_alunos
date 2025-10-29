import 'package:flutter/material.dart';

class RelatorioScreen extends StatelessWidget {
  final List<Map<String, String>> relatorio = [
    {
      'student_id': '001',
      'student_name': 'Alice',
      'date': '2025-10-23',
      'round': '1',
      'status': 'P',
      'recorded_at': '2025-10-23T19:00:00',
      'notes': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatório')),
      body: ListView.builder(
        itemCount: relatorio.length,
        itemBuilder: (context, index) {
          final linha = relatorio[index];
          return ListTile(
            title: Text('${linha['student_name']} - Rodada ${linha['round']}'),
            subtitle: Text('Status: ${linha['status']} | Data: ${linha['date']}'),
          );
        },
      ),
    );
  }
}