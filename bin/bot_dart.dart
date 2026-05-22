import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();
  final token = env['TELEGRAM_TOKEN'];

  print("Bot iniciado...");

  final url = Uri.parse(
    "https://api.telegram.org/bot$token/getUpdates",
  );

  final request = await HttpClient().getUrl(url);

  final response = await request.close();

  final body = await response.transform(utf8.decoder).join();

  final data = jsonDecode(body);

  final ultimoUpdate = data["result"].last;

  print(ultimoUpdate);

  // pega o texto enviado pelo usuário
  final mensagem = ultimoUpdate["message"]["text"];

  print("CPF recebido: $mensagem");

  // valida o CPF
  final cpfValido = validarCPF(mensagem);

  // mostra resultado
  if (cpfValido) {
    print("CPF válido!");
  } else {
    print("CPF inválido!");
  }
}

// função que valida CPF
bool validarCPF(String cpf) {

  // remove pontos e traços
  cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // verifica tamanho
  if (cpf.length != 11) {
    return false;
  }

  // evita CPF com números repetidos
  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
    return false;
  }

  int soma = 0;

  // cálculo do primeiro dígito
  for (int i = 0; i < 9; i++) {
    soma += int.parse(cpf[i]) * (10 - i);
  }

  int resto = (soma * 10) % 11;

  if (resto == 10) {
    resto = 0;
  }

  if (resto != int.parse(cpf[9])) {
    return false;
  }

  soma = 0;

  // cálculo do segundo dígito
  for (int i = 0; i < 10; i++) {
    soma += int.parse(cpf[i]) * (11 - i);
  }

  resto = (soma * 10) % 11;

  if (resto == 10) {
    resto = 0;
  }

  if (resto != int.parse(cpf[10])) {
    return false;
  }

  return true;
}