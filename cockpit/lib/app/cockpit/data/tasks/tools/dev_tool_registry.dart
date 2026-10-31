import 'package:cockpit/app/cockpit/domain/contracts/dev_tool.dart';

/// Primeira ferramenta que reconhece o argv ganha. Registrar outra não altera
/// as que já estavam na lista.
class DevToolRegistry {
  DevToolRegistry(List<DevTool> tools)
    : _tools = List<DevTool>.unmodifiable(tools);

  final List<DevTool> _tools;

  ParsedDevCommand? match(String command, List<String> args) {
    for (final tool in _tools) {
      final parsed = tool.match(command, args);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Implementação de device da ferramenta [toolId], se ela tiver uma.
  DeviceRunTool? deviceTool(String toolId) {
    for (final tool in _tools) {
      if (tool.id == toolId && tool is DeviceRunTool) return tool;
    }
    return null;
  }
}
