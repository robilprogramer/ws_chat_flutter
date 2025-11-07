enum ChatStatus {
  disconnected,
  connecting,
  aiMode,
  connectedToCs;

  String get displayText {
    switch (this) {
      case ChatStatus.disconnected:
        return 'Tidak Terhubung';
      case ChatStatus.connecting:
        return 'Menghubungkan...';
      case ChatStatus.aiMode:
        return 'AI Assistant';
      case ChatStatus.connectedToCs:
        return 'Customer Service';
    }
  }
}
