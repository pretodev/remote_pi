// Contratos de integração de ferramentas com tasks. O executor e a UI só
// conhecem estes tipos — qual binário, quais devices e como reescrever o argv
// mora na implementação (hoje, Flutter).

/// O que o comando faz em relação a um dispositivo ou plataforma.
///
/// - [runOnDevice]: executa a aplicação num device escolhível (`flutter run`).
/// - [buildForPlatform]: alvo de plataforma, sem escolha de device (`flutter build apk`).
/// - [other]: comando da ferramenta que não oferece seletor (`flutter test`).
enum DevOperation { runOnDevice, buildForPlatform, other }

/// Plataforma de execução reconhecida por uma ferramenta.
enum DevPlatform { android, ios, macos, linux, windows, web }

/// SO em que o Cockpit está rodando. Entra na prioridade automática.
enum HostOs { macos, windows, linux }

/// Comando que uma [DevTool] reconheceu. Imutável.
class ParsedDevCommand {
  ParsedDevCommand({
    required this.toolId,
    required this.operation,
    required List<String> invocation,
    this.buildPlatform,
    this.explicitDeviceId,
  }) : invocation = List<String>.unmodifiable(invocation);

  /// Id da ferramenta (`flutter`). Igual a [DevTool.id].
  final String toolId;

  final DevOperation operation;

  /// Plataforma implícita num build (`apk` → [DevPlatform.android]). Null
  /// quando o comando não fixa plataforma.
  final DevPlatform? buildPlatform;

  /// Device já presente no argv (`-d` / `--device-id`), se houver.
  final String? explicitDeviceId;

  /// Prefixo usado para invocar a ferramenta, sem o subcomando.
  /// Ex.: `['flutter']`, `['fvm', 'flutter']`, `['fvm', 'spawn', '3.24.0', 'flutter']`.
  final List<String> invocation;
}

/// Device que a ferramenta sabe executar. [id] é o valor passado ao processo.
class DevDevice {
  const DevDevice({
    required this.id,
    required this.name,
    required this.platform,
  });

  final String id;
  final String name;
  final DevPlatform platform;
}

/// Reconhece o argv de uma task. Devolve null se o comando não é desta ferramenta.
abstract class DevTool {
  String get id;

  ParsedDevCommand? match(String command, List<String> args);
}

/// Ferramenta que executa uma aplicação num device. Quem só identifica comandos
/// implementa [DevTool] e para por aí.
abstract class DeviceRunTool implements DevTool {
  /// Plataformas habilitadas no projeto em [cwd].
  Future<Set<DevPlatform>> platforms(String cwd);

  /// Devices compatíveis com o projeto, na ordem da ferramenta.
  Future<List<DevDevice>> devices(String cwd, ParsedDevCommand command);

  /// Escolha automática. Null se nenhum device compatível está disponível.
  /// Nunca devolve um device cuja plataforma não está em [platforms].
  DevDevice? prefer(
    HostOs host,
    Set<DevPlatform> platforms,
    List<DevDevice> devices,
  );

  /// Argv com exatamente um device [deviceId]. Se o argv já aponta para esse
  /// id, devolve a mesma lista. Caso contrário remove as flags de device e
  /// acrescenta `-d <id>`, preservando o resto.
  List<String> withDevice(List<String> args, String deviceId);
}
