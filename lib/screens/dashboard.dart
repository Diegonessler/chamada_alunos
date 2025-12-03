import 'package:flutter/material.dart';
import '../utils/rodada_simulador.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    RodadaSimulador.iniciarSimulacao(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rodadas = RodadaSimulador.rodadas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Chamadas'),
      ),
      body: ListView.builder(
        itemCount: rodadas.length,
        itemBuilder: (context, index) {
          final rodada = rodadas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('Rodada ${rodada.numero}'),
              subtitle: Text('Estado: ${rodada.estado}'),
              trailing: rodada.estado == 'Em andamento'
                  ? ElevatedButton(
                      child: const Text('Registrar'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/presenca');
                      },
                    )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.history),
        tooltip: 'Ver Histórico',
        onPressed: () {
          Navigator.pushNamed(context, '/historico');
        },
      ),
    );
  }
}