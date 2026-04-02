import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';
import '../models/coaching_models.dart';
import '../services/coaching_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final coachingServiceProvider = Provider<CoachingService>((ref) {
  return CoachingService();
});

final coachingViewModelProvider =
    AsyncNotifierProvider<CoachingViewModel, CoachingState>(
  CoachingViewModel.new,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CoachingState {
  final List<CoachingProgram> programs;
  final CoachingProgram? selectedProgram;
  final List<CoachingMessage> messages;
  final bool isSending;
  final bool isLoadingPlan;
  final Map<String, dynamic>? currentPlan;

  const CoachingState({
    this.programs = const [],
    this.selectedProgram,
    this.messages = const [],
    this.isSending = false,
    this.isLoadingPlan = false,
    this.currentPlan,
  });

  CoachingState copyWith({
    List<CoachingProgram>? programs,
    CoachingProgram? selectedProgram,
    bool clearSelectedProgram = false,
    List<CoachingMessage>? messages,
    bool? isSending,
    bool? isLoadingPlan,
    Map<String, dynamic>? currentPlan,
    bool clearPlan = false,
  }) {
    return CoachingState(
      programs: programs ?? this.programs,
      selectedProgram:
          clearSelectedProgram ? null : (selectedProgram ?? this.selectedProgram),
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingPlan: isLoadingPlan ?? this.isLoadingPlan,
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VIEWMODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CoachingViewModel extends AsyncNotifier<CoachingState> {
  @override
  Future<CoachingState> build() async {
    // Load programs — fallback to hardcoded if API unavailable
    final service = ref.read(coachingServiceProvider);
    List<CoachingProgram> programs;

    try {
      programs = await service.getPrograms();
    } catch (e) {
      AppLogger.warn('Coaching: Could not load programs from API, using defaults: $e');
      programs = _defaultPrograms;
    }

    return CoachingState(programs: programs);
  }

  /// Select a coaching program and show welcome.
  void selectProgram(CoachingProgram program) {
    final current = state.value;
    if (current == null) return;

    final service = ref.read(coachingServiceProvider);
    service.clearHistory(program.id);

    final user = ref.read(currentUserProvider);
    final name = user?.name ?? 'Boss';

    final welcome = CoachingMessage.system(
      '${program.emoji} **${program.title}** — sẵn sàng, $name!\n\n'
      '${program.subtitle}\n\n'
      '💡 Hỏi bất cứ điều gì hoặc nhấn **"Tạo kế hoạch"** để bắt đầu.',
    );

    state = AsyncData(current.copyWith(
      selectedProgram: program,
      messages: [welcome],
      currentPlan: null,
      clearPlan: true,
    ));
  }

  /// Go back to program list.
  void goBack() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      clearSelectedProgram: true,
      messages: [],
      clearPlan: true,
    ));
  }

  /// Send a chat message.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final current = state.value;
    if (current == null || current.selectedProgram == null) return;

    final userMsg = CoachingMessage.user(text.trim());
    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg],
      isSending: true,
    ));

    final service = ref.read(coachingServiceProvider);
    final user = ref.read(currentUserProvider);
    final context = user != null ? 'Tên user: ${user.name}' : null;

    try {
      final response = await service.chat(
        message: text.trim(),
        programId: current.selectedProgram!.id,
        userContext: context,
      );

      final updated = state.value;
      if (updated == null) return;

      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, response],
        isSending: false,
      ));
    } catch (e) {
      final updated = state.value;
      if (updated == null) return;

      final errorMsg = CoachingMessage.system('❌ $e');
      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, errorMsg],
        isSending: false,
      ));
    }
  }

  /// Generate a structured plan.
  Future<void> generatePlan({int? days, String? customGoal}) async {
    final current = state.value;
    if (current == null || current.selectedProgram == null) return;

    state = AsyncData(current.copyWith(isLoadingPlan: true));

    final service = ref.read(coachingServiceProvider);

    try {
      final plan = await service.generatePlan(
        programId: current.selectedProgram!.id,
        days: days,
        customGoal: customGoal,
      );

      final updated = state.value;
      if (updated == null) return;

      // Also add plan summary as a message
      final title = plan['title'] ?? current.selectedProgram!.title;
      final overview = plan['overview'] ?? '';
      final planMsg = CoachingMessage.assistant(
        '📋 **$title**\n\n$overview\n\n'
        '_Kế hoạch đã được tạo! Xem chi tiết bên dưới._',
      );

      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, planMsg],
        currentPlan: plan,
        isLoadingPlan: false,
      ));
    } catch (e) {
      final updated = state.value;
      if (updated == null) return;

      final errorMsg = CoachingMessage.system('❌ Không thể tạo kế hoạch: $e');
      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, errorMsg],
        isLoadingPlan: false,
      ));
    }
  }

  /// Fallback programs when API is unavailable.
  static final _defaultPrograms = [
    const CoachingProgram(id: 'sleep', emoji: '🌙', title: 'Ngủ Sâu Hơn', subtitle: 'Circadian + Routine tối', color: '#6C63FF', defaultDays: 7),
    const CoachingProgram(id: 'focus', emoji: '⚡', title: 'Tập Trung Hơn', subtitle: 'Deep Work + Time-blocking', color: '#F59E0B', defaultDays: 7),
    const CoachingProgram(id: 'learn', emoji: '🧠', title: 'Thành Thạo Skill', subtitle: '5 kỹ thuật học nhanh', color: '#10B981', defaultDays: 30),
    const CoachingProgram(id: 'fitness', emoji: '💪', title: 'Khỏe Hơn', subtitle: '30 ngày · Không cần gym', color: '#EF4444', defaultDays: 30),
    const CoachingProgram(id: 'social', emoji: '📱', title: 'Tăng Follow', subtitle: '30 ngày · Content + Analytics', color: '#EC4899', defaultDays: 30),
    const CoachingProgram(id: 'finance', emoji: '💰', title: 'Kiểm Soát Tiền', subtitle: 'Ngân sách + Tiết kiệm', color: '#14B8A6', defaultDays: 30),
    const CoachingProgram(id: 'business', emoji: '🚀', title: 'Kiếm Tiền Online', subtitle: 'Lộ trình 30 ngày thực chiến', color: '#8B5CF6', defaultDays: 30),
    const CoachingProgram(id: 'stress', emoji: '🧘', title: 'Tâm Lý Ổn Định', subtitle: '7 ngày · Kỹ thuật khoa học', color: '#06B6D4', defaultDays: 7),
    const CoachingProgram(id: 'comms', emoji: '🗣️', title: 'Tự Tin Hơn', subtitle: '30 ngày · Giao tiếp + Storytelling', color: '#F97316', defaultDays: 30),
    const CoachingProgram(id: 'custom', emoji: '✨', title: 'Tùy Chỉnh Cá Nhân', subtitle: 'Nhập mục tiêu của bạn', color: '#A78BFA', defaultDays: 30, isCustom: true),
  ];
}
