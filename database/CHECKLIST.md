# ✅ SABOHUB v2.0 Migration Checklist

## Pre-Migration (DO FIRST!)

- [ ] **Backup .env file**
  ```bash
  cp .env .env.backup
  ```

- [ ] **Backup current database** (if you have production data)
  ```bash
  # Option 1: Using Supabase Dashboard
  # Go to Database → Backups → Create backup
  
  # Option 2: Using pg_dump (if you have PostgreSQL installed)
  pg_dump "postgresql://postgres.vuxuqvgkfjemthbdwsnh:Linh123456789!@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres" > backup.sql
  ```

- [ ] **Read MIGRATION-GUIDE-V2.md completely**

- [ ] **Decide**: Fresh start or data migration?
  - Fresh start = Faster, data lost
  - Data migration = Slower, keeps data (need custom script)

---

## Database Migration

- [ ] **Install dependencies**
  ```bash
  cd database
  npm install pg
  ```

- [ ] **Review what will happen**
  - ⚠️ ALL TABLES will be DROPPED
  - ✅ New schema v2.0 will be created
  - ✅ RLS policies v2.0 will be applied

- [ ] **Run migration**
  ```bash
  node database/apply-new-schema.js
  ```

- [ ] **Verify migration succeeded**
  - Check terminal output for ✅ Success messages
  - No ❌ errors should appear

---

## Supabase Dashboard Setup

- [ ] **Enable Custom Access Token Hook**
  1. Go to: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/hooks
  2. Find "Custom access token" section
  3. Toggle it ON
  4. Select function: `public.custom_access_token_hook`
  5. Click "Save"

- [ ] **Verify hook is enabled**
  - Should show green checkmark
  - Function should be selected

---

## Flutter App Updates

### Step 1: Update Models

- [ ] **Update User model** (lib/models/user.dart)
  ```dart
  // ❌ REMOVE
  final String? storeId;
  
  // ✅ ADD
  final String? branchId;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final Map<String, dynamic>? attributes;
  ```

- [ ] **Update Product model**
  ```dart
  // Change: storeId → branchId
  // Add: attributes, isActive, deletedAt
  ```

- [ ] **Update Order model**
  ```dart
  // Add: branchId, paymentStatus, createdBy
  // Add: subtotal, taxAmount, totalAmount
  // Add: tableNumber, customerName, customerPhone
  ```

- [ ] **Update other models** (Task, Payment, etc.)

### Step 2: Update Queries

- [ ] **Global search and replace**
  - Search: `store_id` → Replace: `branch_id`
  - Search: `storeId` → Replace: `branchId`
  - Search: `StoreId` → Replace: `BranchId`

- [ ] **Update Supabase queries**
  ```dart
  // ❌ OLD
  .eq('store_id', storeId)
  
  // ✅ NEW
  .eq('branch_id', branchId)
  ```

- [ ] **Add required fields to inserts**
  ```dart
  {
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  }
  ```

- [ ] **Update deletes to soft delete**
  ```dart
  // ❌ OLD
  await supabase.from('users').delete().eq('id', id);
  
  // ✅ NEW
  await supabase.from('users').update({
    'deleted_at': DateTime.now().toIso8601String()
  }).eq('id', id);
  ```

### Step 3: Handle New Features

- [ ] **Implement JSONB attributes**
  ```dart
  // Store custom data
  'attributes': {
    'custom_field_1': 'value',
    'custom_field_2': 123,
  }
  ```

- [ ] **Add soft delete filters**
  ```dart
  // Always filter out deleted records
  .is_('deleted_at', null)
  ```

- [ ] **Update inventory queries**
  - Old: `inventory_items`
  - New: `branch_inventory` + `inventory_transactions`

---

## Testing

- [ ] **Create test users**
  ```sql
  -- CEO
  INSERT INTO users (id, email, role, company_id, branch_id, full_name)
  VALUES (
    gen_random_uuid(),
    'ceo@test.com',
    'CEO',
    (SELECT id FROM companies LIMIT 1),
    (SELECT id FROM branches LIMIT 1),
    'Test CEO'
  );
  
  -- Manager
  INSERT INTO users (id, email, role, company_id, branch_id, full_name)
  VALUES (
    gen_random_uuid(),
    'manager@test.com',
    'BRANCH_MANAGER',
    (SELECT id FROM companies LIMIT 1),
    (SELECT id FROM branches LIMIT 1),
    'Test Manager'
  );
  
  -- Staff
  INSERT INTO users (id, email, role, company_id, branch_id, full_name)
  VALUES (
    gen_random_uuid(),
    'staff@test.com',
    'STAFF',
    (SELECT id FROM companies LIMIT 1),
    (SELECT id FROM branches LIMIT 1),
    'Test Staff'
  );
  ```

- [ ] **Test as CEO**
  - Can view all companies? ✅
  - Can view all branches? ✅
  - Can manage all users? ✅
  - Can view all orders? ✅

- [ ] **Test as Branch Manager**
  - Can view own branch only? ✅
  - Can manage branch users? ✅
  - Cannot manage CEO users? ✅
  - Cannot see other branches? ✅

- [ ] **Test as Staff**
  - Can view own profile? ✅
  - Can view assigned tasks? ✅
  - Can create orders? ✅
  - Cannot manage users? ✅
  - Cannot delete data? ✅

- [ ] **Test RLS policies**
  - No infinite recursion errors? ✅
  - Queries are fast? ✅
  - Users only see authorized data? ✅

---

## Force Re-login

- [ ] **Add session check**
  ```dart
  // Check if token has new claims
  final session = supabase.auth.currentSession;
  final claims = session?.user.userMetadata;
  
  if (claims?['user_role'] == null) {
    // Old token format, force re-login
    await supabase.auth.signOut();
    // Navigate to login screen
  }
  ```

- [ ] **Or force logout for all users**
  ```dart
  // In your main.dart or app startup
  await supabase.auth.signOut();
  ```

- [ ] **Test login flow**
  - User logs in
  - JWT contains: user_role, branch_id, company_id
  - App works without errors

---

## Deployment

- [ ] **Test on development first**
  - Run migration on dev database
  - Test thoroughly
  - Fix any issues

- [ ] **Plan production deployment**
  - Schedule downtime window
  - Notify users
  - Prepare rollback plan (backup!)

- [ ] **Deploy to production**
  1. Announce maintenance
  2. Stop accepting new requests
  3. Backup database
  4. Run migration
  5. Update Flutter app
  6. Test critical flows
  7. Open to users

- [ ] **Monitor after deployment**
  - Watch error logs
  - Check query performance
  - Verify RLS working
  - User feedback

---

## Post-Migration Verification

- [ ] **Check all tables exist**
  ```sql
  SELECT table_name 
  FROM information_schema.tables 
  WHERE table_schema = 'public'
  ORDER BY table_name;
  ```

- [ ] **Check RLS enabled**
  ```sql
  SELECT schemaname, tablename, rowsecurity 
  FROM pg_tables 
  WHERE schemaname = 'public'
  AND rowsecurity = true;
  ```

- [ ] **Check policies exist**
  ```sql
  SELECT tablename, policyname 
  FROM pg_policies 
  WHERE schemaname = 'public'
  ORDER BY tablename, policyname;
  ```

- [ ] **Check indexes**
  ```sql
  SELECT 
    schemaname,
    tablename,
    indexname
  FROM pg_indexes
  WHERE schemaname = 'public'
  ORDER BY tablename, indexname;
  ```

- [ ] **Check custom hook**
  ```sql
  SELECT routine_name 
  FROM information_schema.routines 
  WHERE routine_schema = 'public'
  AND routine_name = 'custom_access_token_hook';
  ```

---

## Rollback Plan (If Things Go Wrong)

- [ ] **Have backup ready**
  - Database dump file
  - Old app version

- [ ] **Restore database**
  ```bash
  # Drop new schema
  psql "postgresql://..." -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  
  # Restore from backup
  psql "postgresql://..." < backup.sql
  ```

- [ ] **Revert app code**
  - Git revert to previous commit
  - Redeploy old version

---

## Success Criteria

✅ **Database**
- [ ] No infinite recursion errors
- [ ] All queries complete successfully
- [ ] RLS policies working correctly
- [ ] Performance improved (faster queries)

✅ **Flutter App**
- [ ] No compilation errors
- [ ] No runtime errors
- [ ] All features working
- [ ] Users can login and use app

✅ **Security**
- [ ] Users only see authorized data
- [ ] CEO can access all companies
- [ ] Managers can only access their branch
- [ ] Staff have appropriate limitations

✅ **Performance**
- [ ] Queries execute quickly
- [ ] No slow database calls
- [ ] App feels responsive

---

## 📞 Need Help?

**Issues during migration?**
- Check terminal output for errors
- Look in Supabase Dashboard logs
- Test individual SQL files in SQL Editor

**App not working after migration?**
- Verify Auth Hook is enabled
- Check that users re-logged in
- Inspect JWT token claims
- Test RLS policies manually

**Still stuck?**
- Ask me! I'm here to help! 💪

---

## 🎉 You're Done!

Once all checkboxes are ✅, your SABOHUB v2.0 migration is complete!

**What you achieved:**
- ✅ Fixed infinite recursion error
- ✅ Improved database design
- ✅ Better security with JWT-based RLS
- ✅ Faster query performance
- ✅ Scalable architecture

**Congratulations!** 🚀
