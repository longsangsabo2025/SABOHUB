# 🔄 Error Handling Migration Guide

**Status:** ✅ Pattern Created | 🔄 Migration In Progress

---

## ✅ What Was Done

1. ✅ Created standardized error handling pattern (`src/lib/error-handling.ts`)
2. ✅ Created React Query hook (`src/hooks/use-error-handler.ts`)
3. ✅ Updated `CreateTaskDialog.tsx` as example

---

## 📋 Migration Checklist

### Files to Update

- [x] `src/components/tasks/CreateTaskDialog.tsx` ✅
- [ ] `src/pages/attendance/Attendance.tsx` (5 error handlers)
- [ ] `src/pages/daily-reports/DailyReports.tsx` (1 error handler)
- [ ] `src/pages/reports/ExecutiveReport.tsx` (1 error handler)
- [ ] Other components with error handling

---

## 🔧 How to Migrate

### Before (Old Pattern)

```typescript
onError: (error: Error) => {
  toast({
    title: 'Lỗi',
    description: error.message,
    variant: 'destructive',
  });
}
```

### After (New Pattern)

```typescript
import { useErrorHandler, ErrorCategory } from '@/hooks/use-error-handler';

const { handleError } = useErrorHandler();

// In mutation/query
onError: (error) => {
  handleError(error, {
    category: ErrorCategory.DATABASE,
    context: 'Failed to create task',
    operation: 'createTask',
  });
}
```

---

## 📝 Error Categories

Use appropriate category:

- `ErrorCategory.NETWORK` - Network/fetch errors
- `ErrorCategory.AUTH` - Authentication errors
- `ErrorCategory.VALIDATION` - Input validation errors
- `ErrorCategory.DATABASE` - Database/Supabase errors
- `ErrorCategory.API` - API endpoint errors
- `ErrorCategory.UNKNOWN` - Unknown errors (default)

---

## 🎯 Benefits

1. ✅ Consistent error messages
2. ✅ Automatic Sentry reporting
3. ✅ Better error classification
4. ✅ User-friendly Vietnamese messages
5. ✅ Centralized error handling logic

---

## 🚀 Next Steps

1. Migrate remaining error handlers
2. Add retry logic where appropriate
3. Test error scenarios
4. Monitor Sentry dashboard

---

**Last Updated:** January 2025

