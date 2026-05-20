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
}