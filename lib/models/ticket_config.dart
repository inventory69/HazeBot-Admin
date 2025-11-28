class TicketConfig {
  final List<String> categories;
  final int? autoDeleteAfterCloseDays;
  final bool requireClaim;
  final bool sendTranscriptEmail;
  final String transcriptEmailAddress;

  TicketConfig({
    required this.categories,
    this.autoDeleteAfterCloseDays,
    required this.requireClaim,
    required this.sendTranscriptEmail,
    required this.transcriptEmailAddress,
  });

  factory TicketConfig.fromJson(Map<String, dynamic> json) {
    return TicketConfig(
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Application', 'Bug', 'Support'],
      autoDeleteAfterCloseDays: json['auto_delete_after_close_days'] as int? ?? 7,
      requireClaim: json['require_claim'] as bool? ?? false,
      sendTranscriptEmail: json['send_transcript_email'] as bool? ?? false,
      transcriptEmailAddress: json['transcript_email_address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'auto_delete_after_close_days': autoDeleteAfterCloseDays,
      'require_claim': requireClaim,
      'send_transcript_email': sendTranscriptEmail,
      'transcript_email_address': transcriptEmailAddress,
    };
  }

  TicketConfig copyWith({
    List<String>? categories,
    int? autoDeleteAfterCloseDays,
    bool? requireClaim,
    bool? sendTranscriptEmail,
    String? transcriptEmailAddress,
  }) {
    return TicketConfig(
      categories: categories ?? this.categories,
      autoDeleteAfterCloseDays: autoDeleteAfterCloseDays ?? this.autoDeleteAfterCloseDays,
      requireClaim: requireClaim ?? this.requireClaim,
      sendTranscriptEmail: sendTranscriptEmail ?? this.sendTranscriptEmail,
      transcriptEmailAddress: transcriptEmailAddress ?? this.transcriptEmailAddress,
    );
  }

  // Default configuration
  static TicketConfig get defaultConfig {
    return TicketConfig(
      categories: ['Application', 'Bug', 'Support'],
      autoDeleteAfterCloseDays: 7,
      requireClaim: false,
      sendTranscriptEmail: false,
      transcriptEmailAddress: '',
    );
  }
}
