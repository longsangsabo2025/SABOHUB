# 🧪 SABOHUB COMPREHENSIVE TEST PLAN
**Tester**: QA Team  
**Date**: November 7, 2025  
**App Version**: Production (App Store Published)  
**Test Environment**: Chrome Web + Real Devices

---

## 📋 TEST EXECUTION CHECKLIST

### 🔐 PHASE 1: AUTHENTICATION FLOW (Priority: CRITICAL)

#### Test Case 1.1: Sign Up Flow
- [ ] **Step 1**: Open app → Navigate to Sign Up page
- [ ] **Step 2**: Enter valid email (test@sabohub.com)
- [ ] **Step 3**: Enter valid password (min 6 chars)
- [ ] **Step 4**: Enter full name
- [ ] **Step 5**: Click "Sign Up" button
- [ ] **Expected**: 
  - Success message appears
  - Redirect to email verification page
  - Verification email sent
- [ ] **Edge Cases**:
  - [ ] Invalid email format
  - [ ] Weak password (< 6 chars)
  - [ ] Empty fields
  - [ ] Duplicate email

#### Test Case 1.2: Email Verification
- [ ] **Step 1**: Check email inbox
- [ ] **Step 2**: Click verification link
- [ ] **Expected**: 
  - Email verified successfully
  - Redirect to login page
  - Can now log in
- [ ] **Edge Cases**:
  - [ ] Expired verification link
  - [ ] Already verified email
  - [ ] Invalid verification token

#### Test Case 1.3: Login Flow
- [ ] **Step 1**: Enter verified email
- [ ] **Step 2**: Enter correct password
- [ ] **Step 3**: Click "Login" button
- [ ] **Expected**: 
  - Login successful
  - Redirect to role-based dashboard
  - Session token stored
- [ ] **Edge Cases**:
  - [ ] Wrong password (3 attempts)
  - [ ] Unverified email
  - [ ] Non-existent user
  - [ ] Network timeout

#### Test Case 1.4: Password Reset
- [ ] **Step 1**: Click "Forgot Password"
- [ ] **Step 2**: Enter registered email
- [ ] **Step 3**: Click "Send Reset Link"
- [ ] **Expected**: 
  - Reset email sent
  - Reset link valid for 1 hour
  - Can set new password
- [ ] **Edge Cases**:
  - [ ] Non-existent email
  - [ ] Expired reset link
  - [ ] Weak new password

#### Test Case 1.5: Session Persistence
- [ ] **Step 1**: Login successfully
- [ ] **Step 2**: Close browser
- [ ] **Step 3**: Reopen app
- [ ] **Expected**: 
  - Still logged in
  - Dashboard loads immediately
  - No re-authentication needed
- [ ] **Edge Cases**:
  - [ ] Session timeout (30 mins)
  - [ ] Token expiration
  - [ ] Manual logout

---

### 👥 PHASE 2: ROLE-BASED ACCESS CONTROL (Priority: HIGH)

#### Test Case 2.1: Staff Role Access
- [ ] **Login as**: Staff user
- [ ] **Check Navigation**:
  - [ ] Can see: Tables, Check-in, Tasks, Messages, Company Info
  - [ ] Cannot see: Analytics, Reports, Management pages
- [ ] **Check Permissions**:
  - [ ] Can check-in/out
  - [ ] Can view own tasks
  - [ ] Can view company info (read-only)
  - [ ] Cannot create/delete users
  - [ ] Cannot access CEO features

#### Test Case 2.2: Shift Leader Role Access
- [ ] **Login as**: Shift Leader
- [ ] **Check Navigation**:
  - [ ] Can see: Tasks, Check-in, Messages, Team, Reports, Company Info
  - [ ] Cannot see: CEO analytics, Company creation
- [ ] **Check Permissions**:
  - [ ] Can manage team tasks
  - [ ] Can view team reports
  - [ ] Can assign tasks to staff
  - [ ] Cannot modify company settings

#### Test Case 2.3: Manager Role Access
- [ ] **Login as**: Manager
- [ ] **Check Navigation**:
  - [ ] Can see: Dashboard, Companies, Tasks, Attendance, Analytics, Staff
- [ ] **Check Permissions**:
  - [ ] Can view all company data
  - [ ] Can manage staff
  - [ ] Can view analytics
  - [ ] Cannot delete companies

#### Test Case 2.4: CEO Role Access
- [ ] **Login as**: CEO
- [ ] **Check Navigation**:
  - [ ] Can see: All 8 tabs (Analytics, Tasks, Companies, Documents, AI, Settings, etc.)
- [ ] **Check Permissions**:
  - [ ] Full access to all features
  - [ ] Can create/delete companies
  - [ ] Can manage all users
  - [ ] Can access AI features
  - [ ] Can view financial reports

---

### ⚙️ PHASE 3: CORE FEATURES (Priority: HIGH)

#### Test Case 3.1: Check-in/Check-out Flow
- [ ] **Step 1**: Navigate to Check-in page
- [ ] **Step 2**: Click "Check In" button
- [ ] **Expected**: 
  - Timestamp recorded
  - Location captured (if enabled)
  - Status shows "Checked In"
  - Green indicator appears
- [ ] **Step 3**: Work for some time
- [ ] **Step 4**: Click "Check Out" button
- [ ] **Expected**: 
  - Checkout time recorded
  - Work duration calculated
  - Daily work report generated
  - Status shows "Checked Out"
- [ ] **Edge Cases**:
  - [ ] Check-in twice (should prevent)
  - [ ] Check-out without check-in
  - [ ] Location permission denied
  - [ ] Network failure during check-in

#### Test Case 3.2: Task Management
- [ ] **Create Task**:
  - [ ] Fill task title
  - [ ] Fill description
  - [ ] Set due date
  - [ ] Assign to user
  - [ ] Click "Create"
  - [ ] Expected: Task appears in list
- [ ] **Edit Task**:
  - [ ] Click task card
  - [ ] Modify fields
  - [ ] Save changes
  - [ ] Expected: Changes reflected
- [ ] **Complete Task**:
  - [ ] Mark task as done
  - [ ] Expected: Status updated, notification sent
- [ ] **Delete Task**:
  - [ ] Click delete button
  - [ ] Confirm deletion
  - [ ] Expected: Task removed from list

#### Test Case 3.3: Company Details Page
- [ ] **Navigate**: CEO → Companies → Select company
- [ ] **Check All 10 Tabs**:
  - [ ] 1. Overview (company info, stats)
  - [ ] 2. Employees (list, search, filter)
  - [ ] 3. Tasks (company tasks)
  - [ ] 4. Documents (business docs)
  - [ ] 5. AI Assistant (chat interface)
  - [ ] 6. Attendance (check-in records)
  - [ ] 7. Accounting (transactions, revenue)
  - [ ] 8. Reports (analytics)
  - [ ] 9. Settings (company config)
  - [ ] 10. Team Management
- [ ] **Test Tab Switching**:
  - [ ] Switch between all tabs
  - [ ] Check loading states (shimmer)
  - [ ] Verify data persistence
  - [ ] Check memory usage (should be ~20MB)

#### Test Case 3.4: Accounting Tab
- [ ] **View Summary Cards**:
  - [ ] Total Revenue
  - [ ] Total Expenses
  - [ ] Net Profit
  - [ ] Cash Flow
- [ ] **Create Transaction**:
  - [ ] Click "Add Transaction" button
  - [ ] Fill form (type, amount, date, description)
  - [ ] Submit
  - [ ] Expected: Transaction appears in list
- [ ] **View Charts**:
  - [ ] Revenue trend chart loads
  - [ ] Expense breakdown pie chart
  - [ ] Charts render smoothly
- [ ] **Filter Transactions**:
  - [ ] Filter by date range
  - [ ] Filter by branch
  - [ ] Filter by type

#### Test Case 3.5: Document Management
- [ ] **Upload Document**:
  - [ ] Click "Upload" button
  - [ ] Select file (PDF, image)
  - [ ] Add metadata
  - [ ] Submit
  - [ ] Expected: Document appears in list
- [ ] **View Document**:
  - [ ] Click document card
  - [ ] Expected: Document viewer opens
- [ ] **Download Document**:
  - [ ] Click download button
  - [ ] Expected: File downloads successfully

---

### 🐛 PHASE 4: ERROR HANDLING (Priority: MEDIUM)

#### Test Case 4.1: Network Errors
- [ ] **Disconnect Network**:
  - [ ] Disable WiFi/Mobile data
  - [ ] Try to fetch data
  - [ ] Expected: 
    - Friendly error message
    - Retry button appears
    - Offline mode activates (if cached)

#### Test Case 4.2: Invalid Inputs
- [ ] **Test All Forms**:
  - [ ] Empty required fields
  - [ ] Invalid email formats
  - [ ] Negative numbers in amount fields
  - [ ] Future dates in history fields
  - [ ] Expected: Validation errors shown

#### Test Case 4.3: Edge Cases
- [ ] **Long Text Inputs**: Enter 1000+ chars
- [ ] **Special Characters**: Test SQL injection attempts
- [ ] **Large Files**: Upload 50MB+ files
- [ ] **Rapid Clicks**: Click buttons multiple times quickly
- [ ] **Expected**: App handles gracefully

---

### 🚀 PHASE 5: PERFORMANCE TESTING (Priority: MEDIUM)

#### Test Case 5.1: Loading Performance
- [ ] **Measure Load Times**:
  - [ ] App startup: < 3 seconds ✓
  - [ ] Dashboard load: < 2 seconds ✓
  - [ ] Navigation: < 300ms ✓
  - [ ] Chart rendering: < 1 second ✓

#### Test Case 5.2: Memory Usage
- [ ] **Monitor Memory**:
  - [ ] Initial load: < 50MB ✓
  - [ ] After navigation: < 100MB ✓
  - [ ] Company details tabs: ~20MB per tab ✓
  - [ ] No memory leaks after 10 mins usage ✓

#### Test Case 5.3: Scrolling Performance
- [ ] **Test Large Lists**:
  - [ ] 100+ employees list: Smooth 60fps ✓
  - [ ] 500+ transactions: No jank ✓
  - [ ] Infinite scroll: Works correctly ✓

#### Test Case 5.4: Concurrent Users
- [ ] **Multi-user Testing**:
  - [ ] 5 users accessing same company
  - [ ] Real-time updates work
  - [ ] No data conflicts

---

### 📱 PHASE 6: RESPONSIVE DESIGN (Priority: LOW)

#### Test Case 6.1: Different Screen Sizes
- [ ] **Desktop** (1920x1080): Layout adapts ✓
- [ ] **Tablet** (768x1024): Touch-friendly ✓
- [ ] **Mobile** (375x667): All features accessible ✓

#### Test Case 6.2: Cross-browser Testing
- [ ] **Chrome**: All features work ✓
- [ ] **Safari**: iOS compatibility ✓
- [ ] **Firefox**: No layout issues ✓
- [ ] **Edge**: Windows compatibility ✓

---

## 🔍 BUG TRACKING TEMPLATE

```markdown
### Bug Report #XXX

**Severity**: Critical / High / Medium / Low
**Priority**: P0 / P1 / P2 / P3

**Title**: [Brief description]

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**:
-

**Actual Result**:
-

**Environment**:
- Device: 
- OS: 
- Browser: 
- App Version: 

**Screenshots/Videos**: [Attach]

**Logs**: [Attach]

**Status**: New / In Progress / Fixed / Verified
```

---

## ✅ TEST EXECUTION LOG

| Test Case | Status | Pass/Fail | Notes | Tester | Date |
|-----------|--------|-----------|-------|--------|------|
| 1.1 Sign Up | ⏳ Pending | - | - | - | - |
| 1.2 Email Verify | ⏳ Pending | - | - | - | - |
| 1.3 Login | ⏳ Pending | - | - | - | - |
| ... | ... | ... | ... | ... | ... |

---

**Test Coverage Target**: 80%  
**Critical Bug Tolerance**: 0  
**High Bug Tolerance**: < 5  
**Release Criteria**: All P0/P1 bugs fixed
