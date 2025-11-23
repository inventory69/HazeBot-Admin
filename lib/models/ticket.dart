class Ticket {
  final String ticketId;
  final int ticketNum;
  final String? channelId;
  final String? userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String type;
  final String status;
  final String? createdAt;
  final String? closedAt;
  final String? claimedBy;
  final String? claimedByName;
  final String? assignedTo;
  final String? assignedToName;

  Ticket({
    required this.ticketId,
    required this.ticketNum,
    this.channelId,
    this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.type,
    required this.status,
    this.createdAt,
    this.closedAt,
    this.claimedBy,
    this.claimedByName,
    this.assignedTo,
    this.assignedToName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'] as String,
      ticketNum: json['ticket_num'] as int,
      channelId: json['channel_id'] as String?,
      userId: json['user_id'] as String?,
      username: json['username'] as String? ?? 'Unknown',
      displayName: json['display_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      type: json['type'] as String? ?? 'General',
      status: json['status'] as String? ?? 'Open',
      createdAt: json['created_at'] as String?,
      closedAt: json['closed_at'] as String?,
      claimedBy: json['claimed_by'] as String?,
      claimedByName: json['claimed_by_name'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'ticket_num': ticketNum,
      'channel_id': channelId,
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'type': type,
      'status': status,
      'created_at': createdAt,
      'closed_at': closedAt,
      'claimed_by': claimedBy,
      'claimed_by_name': claimedByName,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
    };
  }

  bool get isOpen => status == 'Open';
  bool get isClaimed => status == 'Claimed';
  bool get isClosed => status == 'Closed';
  bool get hasAssignedUser => assignedTo != null && assignedTo!.isNotEmpty;
}
