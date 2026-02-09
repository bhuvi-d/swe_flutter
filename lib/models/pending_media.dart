/// Model for media pending upload/sync
/// US15: Offline image saving with sync status
class PendingMedia {
  final String id;
  final String filePath;
  final String fileType; // 'video' or 'image'
  final String? voiceTranscription;
  final int durationSeconds;
  final int createdAt;
  final String? base64Content; // US15: For web persistence
  final bool isSynced;

  PendingMedia({
    required this.id,
    required this.filePath,
    required this.fileType,
    this.voiceTranscription,
    this.durationSeconds = 0,
    required this.createdAt,
    this.isSynced = false,
    this.base64Content,
  });

  /// Create a copy with updated fields
  PendingMedia copyWith({
    String? id,
    String? filePath,
    String? fileType,
    String? voiceTranscription,
    int? durationSeconds,
    int? createdAt,
    bool? isSynced,
    String? base64Content,
  }) {
    return PendingMedia(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      base64Content: base64Content ?? this.base64Content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileType': fileType,
      'voiceTranscription': voiceTranscription,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt,
      'isSynced': isSynced,
      'base64Content': base64Content,
    };
  }

  factory PendingMedia.fromJson(Map<String, dynamic> json) {
    return PendingMedia(
      id: json['id'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      voiceTranscription: json['voiceTranscription'],
      durationSeconds: json['durationSeconds'] ?? 0,
      createdAt: json['createdAt'],
      isSynced: json['isSynced'] ?? false,
      base64Content: json['base64Content'],
    );
  }
}
