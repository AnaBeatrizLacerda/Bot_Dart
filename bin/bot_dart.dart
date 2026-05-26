import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {

  // CARREGA AS VARIÁVEIS DO ARQUIVO .ENV
  final env = DotEnv()..load();

  // RECEBE O TOKEN DO BOT DO TELEGRAM
  final token = env['TELEGRAM_TOKEN'];

  // MENSAGEM EXIBIDA NO TERMINAL
  print("Bot iniciado...");

  // VARIÁVEL RESPONSÁVEL POR CONTROLAR
  // AS MENSAGENS JÁ RECEBIDAS
  int updateId = 0;

  // MAP RESPONSÁVEL POR CONTROLAR O ESTADO
  // DA CONVERSA DE CADA USUÁRIO
  Map<int, bool> aguardandoNovoCpf = {};

  // LOOP INFINITO PARA O BOT FICAR ONLINE
  while (true) {

    // URL DA API getUpdates DO TELEGRAM
    final url = Uri.parse(
      "https://api.telegram.org/bot$token/getUpdates?offset=$updateId",
    );

    // FAZ A REQUISIÇÃO PARA A API
    final request = await HttpClient().getUrl(url);

    // RECEBE A RESPOSTA DA API
    final response = await request.close();

    // TRANSFORMA A RESPOSTA EM TEXTO
    final body = await response.transform(utf8.decoder).join();

    // CONVERTE O JSON EM MAP
    final data = jsonDecode(body);

    // VERIFICA SE EXISTEM NOVAS MENSAGENS
    if (data["result"].isEmpty) {

      // AGUARDA 2 SEGUNDOS
      await Future.delayed(Duration(seconds: 2));

      // VOLTA PARA O INÍCIO DO LOOP
      continue;
    }

    // PEGA A ÚLTIMA MENSAGEM RECEBIDA
    final ultimoUpdate = data["result"].last;

    // ATUALIZA O ID DA MENSAGEM
    // PARA EVITAR REPETIÇÕES
    updateId = ultimoUpdate["update_id"] + 1;

    // PEGA O TEXTO DA MENSAGEM
    final mensagem = ultimoUpdate["message"]["text"];

    // PEGA O ID DO CHAT
    final chatId = ultimoUpdate["message"]["chat"]["id"];

    // VARIÁVEL DA RESPOSTA DO BOT
    String resposta;

    // VERIFICA SE O USUÁRIO DIGITOU /start
    if (mensagem == "/start") {

      // DEFINE QUE O USUÁRIO NÃO ESTÁ
      // AGUARDANDO NOVO CPF
      aguardandoNovoCpf[chatId] = false;

      // MENSAGEM INICIAL DO BOT
      resposta =
          "Olá! 👋\n"
          "Eu sou um bot validador de CPF.\n"
          "Envie um CPF para validação.";

    }

    // VERIFICA SE O BOT ESTÁ AGUARDANDO
    // A RESPOSTA DO USUÁRIO
    else if (aguardandoNovoCpf[chatId] == true) {

      // VERIFICA SE O USUÁRIO RESPONDEU "SIM"
      if (mensagem.toLowerCase() == "sim") {

        // DEFINE QUE O USUÁRIO NÃO ESTÁ MAIS
        // AGUARDANDO RESPOSTA
        aguardandoNovoCpf[chatId] = false;

        // PEDE UM NOVO CPF
        resposta = "Perfeito! \nEnvie o próximo CPF.";

      }

      // VERIFICA SE O USUÁRIO RESPONDEU "NÃO"
      else if (
          mensagem.toLowerCase() == "não" ||
          mensagem.toLowerCase() == "nao") {

        // FINALIZA A CONVERSA
        resposta =
            "Até mais! \nObrigado por usar o bot.";

      }

      // CASO O USUÁRIO DIGITE OUTRA COISA
      else {

        // PEDE PARA RESPONDER CORRETAMENTE
        resposta =
            "Responda apenas com SIM ou NÃO.";
      }

    }

    // CASO O USUÁRIO TENHA ENVIADO UM CPF
    else {

      // CHAMA A FUNÇÃO DE VALIDAÇÃO
      final cpfValido = validarCPF(mensagem);

      // VERIFICA SE O CPF É VÁLIDO
      if (cpfValido) {

        // MENSAGEM DE CPF VÁLIDO
        resposta =
            "✅ CPF válido!\n\n"
            "Deseja validar outro CPF?\n"
            "(sim/não)";

      }

      // CASO O CPF SEJA INVÁLIDO
      else {

        // MENSAGEM DE CPF INVÁLIDO
        resposta =
            "❌ CPF inválido!\n\n"
            "Deseja tentar novamente?\n"
            "(sim/não)";
      }

      // DEFINE QUE O BOT ESTÁ AGUARDANDO
      // A RESPOSTA DO USUÁRIO
      aguardandoNovoCpf[chatId] = true;
    }

    // EXIBE A RESPOSTA NO TERMINAL
    print(resposta);

    // URL DA API sendMessage
    final sendUrl = Uri.parse(
      "https://api.telegram.org/bot$token/sendMessage",
    );

    // FAZ UMA REQUISIÇÃO POST
    final sendRequest =
        await HttpClient().postUrl(sendUrl);

    // CRIA O JSON DA MENSAGEM
    final bodyJson = jsonEncode({
      "chat_id": chatId,
      "text": resposta,
    });

    // DEFINE O HEADER COMO JSON UTF-8
    sendRequest.headers.set(
      HttpHeaders.contentTypeHeader,
      "application/json; charset=UTF-8",
    );

    // ENVIA O JSON PARA A API
    sendRequest.add(
      utf8.encode(bodyJson),
    );

    // FINALIZA A REQUISIÇÃO
    await sendRequest.close();

    // AGUARDA 2 SEGUNDOS
    await Future.delayed(Duration(seconds: 2));
  }
}

// FUNÇÃO RESPONSÁVEL POR VALIDAR O CPF
bool validarCPF(String cpf) {

  // REMOVE CARACTERES QUE NÃO SÃO NÚMEROS
  cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // VERIFICA SE O CPF POSSUI 11 DÍGITOS
  if (cpf.length != 11) return false;

  // VERIFICA SE TODOS OS NÚMEROS SÃO IGUAIS
  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

  // VARIÁVEL DA SOMA
  int soma = 0;

  // CALCULA O PRIMEIRO DÍGITO VERIFICADOR
  for (int i = 0; i < 9; i++) {

    soma += int.parse(cpf[i]) * (10 - i);
  }

  // CÁLCULO DO PRIMEIRO DÍGITO
  int primeiroDigito = (soma * 10) % 11;

  // VERIFICA REGRA DO CPF
  if (primeiroDigito == 10) primeiroDigito = 0;

  // COMPARA O DÍGITO GERADO COM O CPF
  if (primeiroDigito != int.parse(cpf[9])) {
    return false;
  }

  // ZERA A SOMA
  soma = 0;

  // CALCULA O SEGUNDO DÍGITO VERIFICADOR
  for (int i = 0; i < 10; i++) {

    soma += int.parse(cpf[i]) * (11 - i);
  }

  // CÁLCULO DO SEGUNDO DÍGITO
  int segundoDigito = (soma * 10) % 11;

  // VERIFICA REGRA DO CPF
  if (segundoDigito == 10) segundoDigito = 0;

  // COMPARA O DÍGITO GERADO COM O CPF
  if (segundoDigito != int.parse(cpf[10])) {
    return false;
  }

  // RETORNA CPF VÁLIDO
  return true;
}