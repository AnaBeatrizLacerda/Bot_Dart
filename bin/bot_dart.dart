import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();
  final token = env['TELEGRAM_TOKEN'];
  print("Bot iniciado...");
  int updateId = 0;
  while (true) {
 final url = Uri.parse(
  "https://api.telegram.org/bot$token/getUpdates?offset=$updateId",
  );
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  if (data["result"].isEmpty) {
  await Future.delayed(Duration(seconds: 2));
  continue;
}
  final ultimoUpdate = data["result"].last;
  updateId = ultimoUpdate["update_id"] + 1;

final mensagem = ultimoUpdate["message"]["text"];
final chatId = ultimoUpdate["message"]["chat"]["id"];

String resposta;

if (mensagem == "/start") {
  resposta =
      "Olá! 👋\n"
      "Eu sou um bot validador de CPF.\n"
      "Envie um CPF para validação.";
} else {
  final cpfValido = validarCPF(mensagem);

  if (cpfValido) {
    resposta = "✅ CPF válido!";
  } else {
    resposta = "❌ CPF inválido!";
  }
}
print(resposta);
final sendUrl = Uri.parse(
  "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatId&text=$resposta",
);

final sendRequest = await HttpClient().getUrl(sendUrl);

await sendRequest.close();
await Future.delayed(Duration(seconds: 2));
}
}
bool validarCPF(String cpf) {
  cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  if (cpf.length != 11) return false;

  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

  int soma = 0;

  for (int i = 0; i < 9; i++) {
    soma += int.parse(cpf[i]) * (10 - i);
  }

  int primeiroDigito = (soma * 10) % 11;

  if (primeiroDigito == 10) primeiroDigito = 0;

  if (primeiroDigito != int.parse(cpf[9])) {
    return false;
  }

  soma = 0;

  for (int i = 0; i < 10; i++) {
    soma += int.parse(cpf[i]) * (11 - i);
  }

  int segundoDigito = (soma * 10) % 11;

  if (segundoDigito == 10) segundoDigito = 0;

  if (segundoDigito != int.parse(cpf[10])) {
    return false;
  }

  return true;
}