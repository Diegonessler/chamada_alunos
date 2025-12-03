import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController matriculaController = TextEditingController();

  void salvarMatricula(BuildContext context) async {
    final matricula = matriculaController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    String nome;

    if (matricula == '1234') {
      nome = 'Diego';
    } else if (matricula == '1212') {
      nome = 'Daniela';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhuma Matrícula Encontrada')),
      );
      return;
    }

    await prefs.setString('matricula', matricula);
    await prefs.setString('nome', nome);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login do Aluno')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: matriculaController,
              decoration: InputDecoration(labelText: 'Digite sua matrícula'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => salvarMatricula(context),
              child: Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}