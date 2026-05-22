const _exemplosCpf = '123.456.789-09';

const _msgStart =
    'Olá! Envie um CPF para que eu possa validar. Exemplo: $_exemplosCpf';

const _msgValido = 'CPF válido ✅';

const _msgInvalido =
    'CPF inválido ❌\nPor favor, envie um CPF com 11 dígitos, por exemplo: $_exemplosCpf';

String _limparCpf(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

int _calcularDigito(List<int> numbers, int peso) {
  final soma = numbers
      .take(peso - 1)
      .indexed
      .fold(0, (acc, e) => acc + e.$2 * (peso - e.$1));
  final resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

bool validarCpf(String cpf) {
  final digits = _limparCpf(cpf.trim());

  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  final numbers = digits.split('').map(int.parse).toList();

  return numbers[9] == _calcularDigito(numbers, 10) &&
      numbers[10] == _calcularDigito(numbers, 11);
}

String replyForMessage(String text) {
  final trimmed = text.trim();
  if (trimmed == '/start') return _msgStart;
  if (validarCpf(trimmed)) return _msgValido;
  return _msgInvalido;
}