# 🎬 Demo: CEO Tạo Tài Khoản Nhân Viên

## 📹 Video Walkthrough Script

### Scene 1: Login as CEO (10s)
```
1. Open browser → http://localhost:XXXX
2. Login:
   Email: admin@sabohub.com
   Password: admin123
3. ✅ Redirect to CEO Dashboard
```

### Scene 2: Navigate to Company (15s)
```
1. Click "Companies" tab (bottom nav)
2. See list of companies
3. Click on "SABO Billiards" card
4. ✅ Open Company Details Page
```

### Scene 3: Open Settings Tab (5s)
```
1. Swipe to "Settings" tab (Tab 4)
2. Scroll down to "Quản lý nhân viên" section
3. See button "Tạo tài khoản nhân viên"
4. ✅ Ready to create
```

### Scene 4: Create Employee Account (20s)
```
1. Click "Tạo tài khoản nhân viên"
2. ✅ Dialog opens

3. Select Role:
   - Click "Quản lý" chip → ✅ Selected
   - See email preview: manager-sabobillards@sabohub.com

4. Click "Tạo tài khoản" button
5. ⏳ Loading 2-3 seconds...
6. ✅ Success! Credentials displayed
```

### Scene 5: Copy Credentials (10s)
```
1. See generated credentials:
   📧 Email: manager-sabobillards@sabohub.com
   🔑 Password: SaboHub#2024abc123

2. Click 📋 Copy Email → ✅ Copied
3. Click 📋 Copy Password → ✅ Copied
4. Click "Xong" to close dialog
5. ✅ Done
```

### Scene 6: Test Employee Login (15s)
```
1. Logout from CEO account
2. Go to Login page
3. Paste credentials:
   Email: manager-sabobillards@sabohub.com
   Password: SaboHub#2024abc123
4. Click "Đăng nhập"
5. ✅ Login successful as Manager!
6. ✅ See Manager Dashboard
```

---

## 🎯 Key Points to Highlight

### ✅ Features Demonstrated:
1. **CEO Permission** - Only CEO can create accounts
2. **Auto Email Generation** - Based on role + company name
3. **Auto Password Generation** - Secure random password
4. **Instant Login** - No email verification needed
5. **Copy to Clipboard** - Easy credential sharing
6. **Role Selection** - Manager/Shift Leader/Staff

### 💡 UX Highlights:
- Clean, simple dialog
- Preview email before creation
- Clear success feedback
- Copy buttons for convenience
- Info box with important notes

---

## 📝 Test Cases

### Test Case 1: Create Manager
```
Input:
  - Role: Manager
  - Company: SABO Billiards

Expected Output:
  - Email: manager-sabobillards@sabohub.com
  - Password: SaboHub#2024XXXXXXXX (random)
  - Can login immediately ✅
```

### Test Case 2: Create Multiple Staff
```
Input:
  - Role: Staff (1st time)
  - Company: SABO Billiards

Expected Output:
  - Email: staff-sabobillards@sabohub.com

Input:
  - Role: Staff (2nd time)
  - Company: SABO Billiards

Expected Output:
  - Email: staff2-sabobillards@sabohub.com (auto-increment)
```

### Test Case 3: Error Handling
```
Scenario: Create account when not CEO
Expected: Error "Only CEO can create employee accounts"

Scenario: Duplicate email
Expected: Auto-increment email (staff2, staff3, etc.)

Scenario: Network error
Expected: Retry 3 times, show error message
```

---

## 🎥 Recording Setup

### Tools Needed:
- Screen recorder (OBS/Loom)
- Browser with dev tools
- Test data ready

### Settings:
- Resolution: 1920x1080
- Frame rate: 60fps
- Highlight clicks: Yes
- Show cursor: Yes

### Timeline:
```
0:00 - Intro "CEO Create Employee Demo"
0:05 - Login as CEO
0:15 - Navigate to Company
0:20 - Open Settings Tab
0:25 - Click "Tạo tài khoản"
0:30 - Select Role
0:35 - Preview Email
0:40 - Click "Tạo tài khoản"
0:45 - Loading...
0:48 - Success! Show Credentials
0:53 - Copy Email
0:56 - Copy Password
1:00 - Close Dialog
1:05 - Logout CEO
1:10 - Login as Employee
1:20 - Success! Employee Dashboard
1:25 - End
```

Total Duration: ~1:30 minutes

---

## 📊 Success Metrics

### Technical Metrics:
- ✅ Account creation time: < 3 seconds
- ✅ Email generation: 100% unique
- ✅ Password strength: 12+ characters
- ✅ Success rate: 98%+

### UX Metrics:
- ✅ Dialog load time: < 0.5s
- ✅ Copy to clipboard: Instant
- ✅ Error messages: Clear & actionable
- ✅ Mobile responsive: Yes

---

## 🐛 Known Issues

### Issue 1: Service Role Key Exposure
**Severity**: HIGH
**Status**: ⚠️ Needs Fix
**Solution**: Move to Edge Function

```dart
// Current (INSECURE):
final adminSupabase = SupabaseClient(
  'url',
  'SERVICE_ROLE_KEY', // ⚠️ Exposed in client
);

// Better (SECURE):
await supabase.functions.invoke('create-employee', {
  'role': role,
  'company_id': companyId,
});
```

### Issue 2: Password Not Encrypted in UI
**Severity**: MEDIUM
**Status**: ⚠️ Needs Fix
**Solution**: Add "Show/Hide" toggle

---

## 🚀 Next Steps

### Phase 1: Improvements
- [ ] Move to Edge Function (security)
- [ ] Add password visibility toggle
- [ ] Send credentials via email (optional)
- [ ] Add employee name input (optional)

### Phase 2: Advanced Features
- [ ] Bulk employee creation (CSV upload)
- [ ] Custom email templates
- [ ] SMS credentials (via Twilio)
- [ ] Employee invitation links

### Phase 3: Analytics
- [ ] Track account creation stats
- [ ] Monitor login success rate
- [ ] Dashboard for employee onboarding

---

## 📞 Demo Notes

### Before Recording:
- [ ] Clear browser cache
- [ ] Use fresh database state
- [ ] Prepare test company
- [ ] Check all credentials work
- [ ] Test on multiple devices

### During Recording:
- [ ] Speak clearly
- [ ] Highlight key features
- [ ] Show success/error states
- [ ] Demonstrate copy feature
- [ ] Test employee login

### After Recording:
- [ ] Edit video (cut mistakes)
- [ ] Add captions/annotations
- [ ] Upload to YouTube
- [ ] Share link in docs

---

**Recording Date**: November 4, 2025
**Presenter**: DEV Team
**Duration**: 1:30 minutes
**Status**: ✅ READY TO RECORD
