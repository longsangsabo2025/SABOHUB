# 🎯 Quick Test - Báo Cáo Tự Động Cuối Ngày

## ⚡ 30 Giây Test

### 1. Navigate (5s)
```
Manager Dashboard → "Hoạt động" → Tap "🧪 Test: Báo cáo Tự động"
```

### 2. Generate (10s)
```
Tap "🚀 Simulate Checkout & Generate Report"
→ Wait 1-2s
→ See green card with report
```

### 3. Dialog (15s)
```
Tap "👁️ Preview Report Dialog"
→ View/edit fields
→ Tap "Submit"
→ Done! ✅
```

---

## 📊 Expected Results

| Item | Value |
|------|-------|
| Work Time | 8:00 - 17:30 (9.5h) |
| Tasks Done | 2 tasks |
| Rating | "Tốt" (Good) |
| Summary | AI-generated with emoji |
| Dialog | Editable fields work |

---

## 🎨 Visual Guide

```
┌─────────────────────────────────────┐
│  Manager Dashboard                  │
├─────────────────────────────────────┤
│  [Hoạt động]                       │
│                                     │
│  ┌─────────┐  ┌─────────┐         │
│  │ Quản lý │  │ Đơn hàng│         │
│  │   bàn   │  │         │         │
│  └─────────┘  └─────────┘         │
│                                     │
│  ┌─────────┐  ┌─────────┐         │
│  │ Kho hàng│  │ Báo cáo │         │
│  └─────────┘  └─────────┘         │
│                                     │
│  ┌────────────────────────────────┐│
│  │ 🧪 Test: Báo cáo Tự động      ││ ← TAP HERE
│  │ Kiểm tra tính năng...         ││
│  └────────────────────────────────┘│
└─────────────────────────────────────┘
```

---

## ✅ Checklist

- [ ] App running
- [ ] Logged in as Manager
- [ ] Dashboard visible
- [ ] Test card found (indigo)
- [ ] Generate works
- [ ] Report displays
- [ ] Dialog opens
- [ ] Fields editable
- [ ] Submit works

---

## 🐛 Quick Fix

**Problem**: Can't find test card  
**Fix**: Scroll down in "Hoạt động" section

**Problem**: Generate doesn't work  
**Fix**: Check console for errors

**Problem**: Dialog doesn't open  
**Fix**: Generate report first

---

## 📱 Files

- **Test Page**: `lib/pages/test/daily_report_test_page.dart`
- **Navigation**: `lib/pages/manager/manager_dashboard_page.dart`
- **Service**: `lib/services/daily_work_report_service.dart`
- **Dialog**: `lib/widgets/work_report_preview_dialog.dart`

---

## 🎯 One-Liner

> "Manager Dashboard → Tap indigo test card → Simulate → Preview → Dialog → Submit"

**Done!** 🎉
