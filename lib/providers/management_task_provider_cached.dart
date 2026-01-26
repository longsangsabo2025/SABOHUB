// MIGRATED TO REAL PROVIDERS - Re-exports from cached_providers.dart
// This file is kept for backward compatibility

export 'cached_providers.dart'
    show
        // Task providers
        cachedManagerAssignedTasksProvider,
        cachedManagerCreatedTasksProvider,
        cachedTaskStatisticsProvider,
        cachedCeoStrategicTasksProvider,
        cachedPendingApprovalsProvider,
        cachedCompanyTaskStatisticsProvider,
        cachedManagerTeamMembersProvider,
        // Refresh functions
        refreshManagerAssignedTasks,
        refreshManagerCreatedTasks,
        refreshAllManagementTasks,
        // Service providers
        managementTaskServiceProvider;
