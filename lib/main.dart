import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'screens/presenca.dart';
import 'screens/historico.dart';
import 'screens/relatorio.dart';

void main() {
  runApp(ChamadaApp());
}

class ChamadaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamada Automatizada',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/presenca': (context) => PresencaScreen(), 
        '/historico': (context) => HistoricoScreen(),
        '/relatorio': (context) => RelatorioScreen(),
      },
    );
  }
}
