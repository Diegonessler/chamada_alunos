import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RelatorioUtil {
  static Future<void> gerarCSV(List<Map<String, String>> dados, String nomeArquivo) async {
    final StringBuffer buffer = StringBuffer();

    // Cabeçalho
    buffer.writeln('Nome,Data,Presença');

    // Dados
    for (var item in dados) {
      buffer.writeln('${item['nome']},${item['data']},${item['presenca']}');
    }

    // Diretório
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nomeArquivo.csv';
    final file = File(path);

    await file.writeAsString(buffer.toString());
    print('Relatório gerado em: $path');
  }
}