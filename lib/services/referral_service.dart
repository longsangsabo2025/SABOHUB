import '../core/services/base_service.dart';
import '../models/referral_model.dart';

/// Service for Employee Referral System.
///
/// Manages referrals CRUD and stats via Supabase `referrals` table.
/// Handles gracefully if the table does not exist yet.
class ReferralService extends BaseService {
  @override
  String get serviceName => 'ReferralService';

  // ──────────────────────────────────────────────
  // Get My Referrals
  // ──────────────────────────────────────────────

  /// Fetch all referrals created by [employeeId], newest first.
  Future<List<Referral>> getMyReferrals(String employeeId) async {
    return safeCall(
      operation: 'getMyReferrals',
      action: () async {
        try {
          final data = await client
              .from('referrals')
              .select()
              .eq('referrer_id', employeeId)
              .order('created_at', ascending: false);

          return (data as List)
              .map((e) => Referral.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          // Table may not exist yet — return empty list gracefully
          logInfo('getMyReferrals', 'Error or table missing: $e');
          return <Referral>[];
        }
      },
    );
  }

  // ──────────────────────────────────────────────
  // Create Referral
  // ──────────────────────────────────────────────

  /// Create a new referral entry.
  Future<Referral> createReferral({
    required String referrerId,
    required String referrerName,
    required String refereeName,
    required String refereePhone,
    required String refereeEmail,
    String? position,
    String? companyId,
    String? note,
    int rewardAmount = 50,
  }) async {
    return safeCall(
      operation: 'createReferral',
      action: () async {
        final response = await client
            .from('referrals')
            .insert({
              'referrer_id': referrerId,
              'referrer_name': referrerName,
              'referee_name': refereeName,
              'referee_phone': refereePhone,
              'referee_email': refereeEmail,
              'position': position,
              'company_id': companyId,
              'note': note,
              'status': ReferralStatus.pending.value,
              'reward_amount': rewardAmount,
            })
            .select()
            .single();

        return Referral.fromJson(response);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Get Company Referrals (CEO / Manager)
  // ──────────────────────────────────────────────

  /// Fetch all referrals for a [companyId], newest first.
  Future<List<Referral>> getCompanyReferrals(String companyId) async {
    return safeCall(
      operation: 'getCompanyReferrals',
      action: () async {
        try {
          final data = await client
              .from('referrals')
              .select()
              .eq('company_id', companyId)
              .order('created_at', ascending: false);

          return (data as List)
              .map((e) => Referral.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          logInfo('getCompanyReferrals', 'Error or table missing: $e');
          return <Referral>[];
        }
      },
    );
  }

  // ──────────────────────────────────────────────
  // Update Referral Status
  // ──────────────────────────────────────────────

  /// Update the status of a referral (accept / reject / expire).
  Future<Referral> updateReferralStatus(
    String referralId,
    ReferralStatus status,
  ) async {
    return safeCall(
      operation: 'updateReferralStatus',
      action: () async {
        final updateData = <String, dynamic>{
          'status': status.value,
        };
        if (status != ReferralStatus.pending) {
          updateData['resolved_at'] = DateTime.now().toIso8601String();
        }

        final response = await client
            .from('referrals')
            .update(updateData)
            .eq('id', referralId)
            .select()
            .single();

        return Referral.fromJson(response);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Referral Stats
  // ──────────────────────────────────────────────

  /// Calculate referral stats for an employee.
  Future<ReferralStats> getReferralStats(String employeeId) async {
    return safeCall(
      operation: 'getReferralStats',
      action: () async {
        try {
          final data = await client
              .from('referrals')
              .select('status, reward_amount')
              .eq('referrer_id', employeeId);

          final list = data as List;
          if (list.isEmpty) return ReferralStats.empty();

          int total = list.length;
          int accepted = 0;
          int pending = 0;
          int rejected = 0;
          int totalRewards = 0;

          for (final row in list) {
            final s = row['status'] as String? ?? 'pending';
            final reward = (row['reward_amount'] as num?)?.toInt() ?? 0;

            switch (s) {
              case 'accepted':
                accepted++;
                totalRewards += reward;
                break;
              case 'pending':
                pending++;
                break;
              case 'rejected':
                rejected++;
                break;
            }
          }

          return ReferralStats(
            total: total,
            accepted: accepted,
            pending: pending,
            rejected: rejected,
            totalRewards: totalRewards,
          );
        } catch (e) {
          logInfo('getReferralStats', 'Error or table missing: $e');
          return ReferralStats.empty();
        }
      },
    );
  }
}
