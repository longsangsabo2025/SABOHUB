# 🧪 Test Quick Login Buttons

## Test Plan: Đăng Nhập Nhanh với Tài Khoản Demo

**Test Date**: 2025-11-07  
**App Status**: Running on Chrome  
**Supabase**: ✅ Connected  

---

## 📋 Test Cases

### Test Case 1: CEO Quick Login
**Account**: longsangsabo1@gmail.com  
**Password**: Acookingoil123@  
**Expected Role**: CEO  

#### Steps:
1. ✅ Open app in Chrome (already running)
2. ⏳ Scroll to "Quick Login" section (purple box)
3. ⏳ Click **"CEO - longsangsabo1@gmail.com"** button
4. ⏳ Wait for loading indicator
5. ⏳ Verify redirect to CEO Dashboard

#### Expected Results:
- Loading indicator shows
- No error messages
- Redirect to `/ceo` route
- Dashboard displays CEO features
- User name shows in header
- Session is saved

---

### Test Case 2: Manager Quick Login
**Account**: ngocdiem1112@gmail.com  
**Password**: 123456  
**Expected Role**: Manager  

#### Steps:
1. ⏳ Logout from CEO account (if logged in)
2. ⏳ Return to login page
3. ⏳ Scroll to "Quick Login" section
4. ⏳ Click **"Manager - ngocdiem1112@gmail.com"** button
5. ⏳ Wait for loading indicator
6. ⏳ Verify redirect to Manager Dashboard

#### Expected Results:
- Loading indicator shows
- No error messages
- Redirect to `/manager` route
- Dashboard displays Manager features
- User name shows in header
- Session is saved

---

## 🐛 Potential Issues to Check

### Issue 1: Session Restore Race Condition (Previously Fixed)
**Status**: ✅ FIXED  
**Fix Applied**: 
- `auth_provider.dart` returns `AuthState(isLoading: true)` 
- `app_router.dart` checks `isLoading` before redirect

**Test**: Login should work on FIRST click (no multiple clicks needed)

### Issue 2: Email Not Verified
**Status**: ✅ Should be OK (demo accounts are verified)

### Issue 3: Account Inactive
**Status**: ✅ Should be OK (demo accounts are active)

### Issue 4: Loading State
**Test**: Button should show CircularProgressIndicator during login

---

## 📊 Test Execution

### Manual Test Instructions:

1. **Mở Chrome tab** với app (localhost)
2. **Verify Login Screen** shows:
   - Email field
   - Password field
   - "Đăng nhập" button (blue)
   - Quick Login section (purple box with 2 buttons)
   - "🍎 Đăng nhập với Apple" button (black)

3. **Test CEO Login**:
   ```
   Click: CEO button (purple)
   Expected: Loading → Redirect to CEO Dashboard
   Verify: URL changes to /ceo
   Verify: Dashboard loads with CEO features
   ```

4. **Test Manager Login**:
   ```
   Click: Logout (in dashboard)
   Click: Manager button (green)
   Expected: Loading → Redirect to Manager Dashboard
   Verify: URL changes to /manager
   Verify: Dashboard loads with Manager features
   ```

---

## ✅ Success Criteria

- [ ] CEO button triggers login
- [ ] Manager button triggers login
- [ ] Loading indicator appears
- [ ] No console errors
- [ ] Redirect to correct dashboard
- [ ] Session persists after reload
- [ ] Logout works correctly
- [ ] Can switch between accounts

---

## 🔍 Debug Checklist

If login fails, check:

### Browser Console (F12):
```javascript
// Check for errors
console.log('Check for red errors')

// Check Supabase auth
supabase.auth.getSession()

// Check auth state
// (View in React DevTools or console)
```

### Network Tab:
- Check POST to Supabase auth endpoint
- Verify 200 response
- Check JWT token in response

### Application Tab:
- Check localStorage for auth token
- Check localStorage for user data
- Verify session timeout settings

---

## 📝 Test Results

### Test Run 1: [Date/Time]

#### CEO Login:
- [ ] Button clicked successfully
- [ ] Loading indicator shown
- [ ] Redirect to /ceo
- [ ] Dashboard loaded
- [ ] User data displayed
- [ ] Session saved
- **Status**: ⏳ Pending / ✅ Pass / ❌ Fail
- **Notes**: 

#### Manager Login:
- [ ] Button clicked successfully
- [ ] Loading indicator shown
- [ ] Redirect to /manager
- [ ] Dashboard loaded
- [ ] User data displayed
- [ ] Session saved
- **Status**: ⏳ Pending / ✅ Pass / ❌ Fail
- **Notes**: 

---

## 🐛 Issues Found

### Issue #1: [Title]
**Severity**: Critical / Major / Minor  
**Description**:  
**Steps to Reproduce**:  
**Expected**:  
**Actual**:  
**Fix**:  

---

## 📸 Screenshots

Add screenshots here if issues found:
- Login screen
- Error messages
- Console logs
- Network tab

---

## 🎯 Next Steps

After testing:

1. ✅ If all pass → Mark feature as ready for production
2. ❌ If fails → Debug and fix issues
3. 📝 Update documentation with findings
4. 🚀 Prepare for iOS TestFlight testing

---

**Tester**: [Your Name]  
**Test Environment**: Chrome, localhost  
**Backend**: Supabase Production  
**Build**: Development Mode  

---

## 🔗 Related Files

- `lib/pages/auth/login_page.dart` (lines 679-730) - Quick Login UI
- `lib/providers/auth_provider.dart` (lines 300-370) - Login method
- `lib/core/router/app_router.dart` (lines 140-180) - Routing logic
- `BUGS-FOUND-QA-SESSION.md` - Bug #1 (Session Race Condition - FIXED)
