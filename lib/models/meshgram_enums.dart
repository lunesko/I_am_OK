/// MeshGram — переліки для транспорту, статусів та mesh-вузлів.

/// Статус чек-іну "Я ОК".
enum CheckinStatus {
  OK,    // 💚 Я ОК
  BUSY,  // 💛 Зайнятий
  LATER, // 💙 Зателефоную
  HUG,   // 🤍 Обійми
}

/// Тип транспорту доставки повідомлення.
enum TransportType {
  FIREBASE,   // Через інтернет (Firestore/FCM)
  MESHGRAM,   // Через mesh (Wi‑Fi Direct / BLE / LoRa)
  HYBRID,     // Частково mesh, частково internet
  LOCAL_QUEUE,// Немає інтернету й mesh — черга локально
}

/// Тип з'єднання mesh-вузла.
enum MeshConnectionType {
  WIFI_DIRECT,
  BLUETOOTH_LE,
  LORA,
  USB_OTG, // Для LoRa модулів
}

/// Статус голосового повідомлення.
enum VoiceMessageStatus {
  RECORDING,
  ENCODING,
  SENDING,
  SENT,
  RECEIVING,
  RECEIVED,
  PLAYING,
  FAILED,
}

// --- Хелпери ---

extension CheckinStatusX on CheckinStatus {
  String get value {
    switch (this) {
      case CheckinStatus.OK: return 'ok';
      case CheckinStatus.BUSY: return 'busy';
      case CheckinStatus.LATER: return 'later';
      case CheckinStatus.HUG: return 'hug';
    }
  }

  String get emoji {
    switch (this) {
      case CheckinStatus.OK: return '💚';
      case CheckinStatus.BUSY: return '💛';
      case CheckinStatus.LATER: return '💙';
      case CheckinStatus.HUG: return '🤍';
    }
  }

  String get displayText {
    switch (this) {
      case CheckinStatus.OK: return 'Я ОК';
      case CheckinStatus.BUSY: return 'Все нормально, зайнятий';
      case CheckinStatus.LATER: return 'Зателефоную пізніше';
      case CheckinStatus.HUG: return 'Обійми';
    }
  }
}

extension CheckinStatusParse on String {
  CheckinStatus get toCheckinStatus {
    switch (this) {
      case 'ok': return CheckinStatus.OK;
      case 'busy': return CheckinStatus.BUSY;
      case 'later': return CheckinStatus.LATER;
      case 'hug': return CheckinStatus.HUG;
      default: return CheckinStatus.OK;
    }
  }
}

extension TransportTypeX on TransportType {
  String get value {
    switch (this) {
      case TransportType.FIREBASE: return 'FIREBASE';
      case TransportType.MESHGRAM: return 'MESHGRAM';
      case TransportType.HYBRID: return 'HYBRID';
      case TransportType.LOCAL_QUEUE: return 'LOCAL_QUEUE';
    }
  }
}

TransportType transportTypeFromString(String? v) {
  switch (v) {
    case 'MESHGRAM': return TransportType.MESHGRAM;
    case 'HYBRID': return TransportType.HYBRID;
    case 'LOCAL_QUEUE': return TransportType.LOCAL_QUEUE;
    default: return TransportType.FIREBASE;
  }
}

extension MeshConnectionTypeX on MeshConnectionType {
  String get value {
    switch (this) {
      case MeshConnectionType.WIFI_DIRECT: return 'WIFI_DIRECT';
      case MeshConnectionType.BLUETOOTH_LE: return 'BLUETOOTH_LE';
      case MeshConnectionType.LORA: return 'LORA';
      case MeshConnectionType.USB_OTG: return 'USB_OTG';
    }
  }
}

MeshConnectionType meshConnectionTypeFromString(String? v) {
  switch (v) {
    case 'BLUETOOTH_LE': return MeshConnectionType.BLUETOOTH_LE;
    case 'LORA': return MeshConnectionType.LORA;
    case 'USB_OTG': return MeshConnectionType.USB_OTG;
    default: return MeshConnectionType.WIFI_DIRECT;
  }
}
