import 'package:network_info_plus/network_info_plus.dart';

Future<bool> estaNaRedeDaEscola() async {
  final info = NetworkInfo();
  final ssid = await info.getWifiName();

  print('SSID atual: $ssid');
  
  // rede que deve ser conectado
  const redePermitida = 'NESSLER2G';

  if (ssid == null || ssid.contains('unknown')) {
    print('SSID inacessível ou localização desativada');
    return false;
  }

  // Remove aspas se existirem
  final ssidLimpo = ssid.replaceAll('"', '');

  return ssidLimpo == redePermitida;
}