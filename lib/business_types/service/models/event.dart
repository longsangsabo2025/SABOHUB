// SABO Corporation — Event Model

enum EventType {
  tournament('tournament', 'Giải đấu'),
  mediaProduction('media_production', 'Sản xuất nội dung'),
  brandActivation('brand_activation', 'Brand activation'),
  workshop('workshop', 'Workshop'),
  meetup('meetup', 'Gặp mặt'),
  livestream('livestream', 'Livestream'),
  sponsorship('sponsorship', 'Tài trợ'),
  other('other', 'Khác');

  final String value;
  final String label;
  const EventType(this.value, this.label);

  static EventType fromString(String s) {
    return EventType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => EventType.other,
    );
  }
}

enum EventStatus {
  planning('planning', 'Lên kế hoạch'),
  confirmed('confirmed', 'Đã xác nhận'),
  inProgress('in_progress', 'Đang diễn ra'),
  completed('completed', 'Hoàn thành'),
  cancelled('cancelled', 'Đã hủy'),
  postponed('postponed', 'Tạm hoãn');

  final String value;
  final String label;
  const EventStatus(this.value, this.label);

  static EventStatus fromString(String s) {
    return EventStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => EventStatus.planning,
    );
  }
}

class Event {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final EventType eventType;
  final EventStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venueName;
  final String? venueAddress;
  final bool isOnline;
  final String? onlineUrl;
  final double budget;
  final double actualCost;
  final double revenue;
  final int expectedAttendees;
  final int actualAttendees;
  final String? tournamentId;
  final String? managerId;
  final String? createdBy;
  final String? bannerUrl;
  final String? notes;
  final List<String>? tags;
  final bool isActive;
  final DateTime? createdAt;

  Event({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.eventType = EventType.other,
    this.status = EventStatus.planning,
    this.startDate,
    this.endDate,
    this.venueName,
    this.venueAddress,
    this.isOnline = false,
    this.onlineUrl,
    this.budget = 0,
    this.actualCost = 0,
    this.revenue = 0,
    this.expectedAttendees = 0,
    this.actualAttendees = 0,
    this.tournamentId,
    this.managerId,
    this.createdBy,
    this.bannerUrl,
    this.notes,
    this.tags,
    this.isActive = true,
    this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventType: EventType.fromString(json['event_type'] ?? ''),
      status: EventStatus.fromString(json['status'] ?? ''),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      venueName: json['venue_name'],
      venueAddress: json['venue_address'],
      isOnline: json['is_online'] ?? false,
      onlineUrl: json['online_url'],
      budget: (json['budget'] ?? 0).toDouble(),
      actualCost: (json['actual_cost'] ?? 0).toDouble(),
      revenue: (json['revenue'] ?? 0).toDouble(),
      expectedAttendees: json['expected_attendees'] ?? 0,
      actualAttendees: json['actual_attendees'] ?? 0,
      tournamentId: json['tournament_id'],
      managerId: json['manager_id'],
      createdBy: json['created_by'],
      bannerUrl: json['banner_url'],
      notes: json['notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'title': title,
        'description': description,
        'event_type': eventType.value,
        'status': status.value,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'venue_name': venueName,
        'venue_address': venueAddress,
        'is_online': isOnline,
        'online_url': onlineUrl,
        'budget': budget,
        'actual_cost': actualCost,
        'revenue': revenue,
        'expected_attendees': expectedAttendees,
        'actual_attendees': actualAttendees,
        'tournament_id': tournamentId,
        'manager_id': managerId,
        'banner_url': bannerUrl,
        'notes': notes,
        'tags': tags,
      };

  /// Profit / Loss
  double get profit => revenue - actualCost;

  /// Budget utilization (0.0 - 1.0)
  double get budgetUtilization {
    if (budget == 0) return 0;
    return (actualCost / budget).clamp(0.0, 2.0);
  }

  /// Attendance rate
  double get attendanceRate {
    if (expectedAttendees == 0) return 0;
    return (actualAttendees / expectedAttendees).clamp(0.0, 2.0);
  }

  /// Is upcoming?
  bool get isUpcoming =>
      status == EventStatus.planning || status == EventStatus.confirmed;

  /// Is live?
  bool get isLive => status == EventStatus.inProgress;
}
