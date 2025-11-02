# 🚀 SABOHUB Database Setup - CLEAN START

## 📋 Overview
This guide helps you set up a **BRAND NEW** Supabase database from scratch with proper configuration.

---

## ✅ Step 1: Create New Supabase Project

1. Go to: https://supabase.com/dashboard
2. Click **"New Project"**
3. Fill in:
   - **Name**: `sabohub-new` (or any name you want)
   - **Database Password**: Choose a **STRONG** password
   - **Region**: Choose closest to you (e.g., `ap-southeast-1` for Singapore)
4. Click **"Create new project"**
5. Wait 2-3 minutes for provisioning

---

## ✅ Step 2: Get Your Credentials

### 2.1 Get API Keys
1. Go to: **Settings → API**
2. Copy these values:
   - **Project URL**: `https://[PROJECT_REF].supabase.co`
   - **anon/public key**: `eyJhbG...`
   - **service_role key**: `eyJhbG...`

### 2.2 Get Database Password
1. Go to: **Settings → Database**
2. Scroll to **"Connection string"**
3. Copy the **Database Password** (the one you set in Step 1)

### 2.3 Get Connection String
1. Go to: **Settings → Database → Connection string**
2. Select **"Session mode"** (NOT Transaction mode)
3. Copy the URI connection string
4. **IMPORTANT**: Make sure it uses **port 5432** (not 6543)

---

## ✅ Step 3: Update .env File

Open `d:\0.APP\3110\rork-sabohub-255\.env` and update:

```env
# Replace these with your NEW project values:
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...YOUR_SERVICE_ROLE_KEY
SUPABASE_CONNECTION_STRING=postgresql://postgres.YOUR_PROJECT_REF:YOUR_PASSWORD@aws-0-REGION.pooler.supabase.com:5432/postgres
SUPABASE_DB_PASSWORD=YOUR_DATABASE_PASSWORD
```

---

## ✅ Step 4: Run Database Migration

```powershell
cd d:\0.APP\3110\rork-sabohub-255\database
node migrate-new-database.js
```

This will:
1. ✅ Create all tables (60 tables)
2. ✅ Apply RLS policies (21 tables with security)
3. ✅ Create custom_access_token_hook function
4. ✅ Create test company & branch
5. ✅ Create test CEO user

---

## ✅ Step 5: Enable Auth Hook

1. Go to: **Authentication → Hooks**
2. Find **"Custom Access Token Hook"**
3. Toggle it **ON**
4. Select:
   - **Schema**: `public`
   - **Function**: `custom_access_token_hook`
5. Click **"Save"**

---

## ✅ Step 6: Test Everything

```powershell
cd d:\0.APP\3110\rork-sabohub-255\database
node test-jwt-token.js
```

Expected output:
```
🎉 SUCCESS! Auth Hook is working correctly!

✅ Custom Claims Found in JWT Token:
   ✅ user_role: CEO
   ✅ company_id: [UUID]
   ✅ branch_id: [UUID]

✅ RLS Policies will now work properly!
```

---

## 🎯 What You Get

After completing these steps, you'll have:

- ✅ **60 tables** with consistent naming (no store_id, all branch_id)
- ✅ **21 tables protected** by Row Level Security
- ✅ **JWT-based authentication** with custom claims
- ✅ **Multi-company/multi-branch** support
- ✅ **Test data** ready for development
- ✅ **Clean, documented schema**

---

## 📊 Database Schema Summary

### Core Tables:
- `companies` - Company management
- `branches` - Branch/location management  
- `users` - User accounts with roles

### Business Tables:
- `products`, `product_categories`
- `orders`, `order_items`
- `payments`
- `branch_inventory`, `inventory_transactions`
- `tables`, `table_sessions`

### Operations:
- `tasks`, `task_comments`
- `shifts`, `attendances`
- `notifications`

---

## ⚠️ Important Notes

1. **Port 5432**: Always use Session Pooler (5432) for migrations, NOT Transaction Pooler (6543)
2. **Strong Password**: Use a secure database password (not "password123")
3. **Auth Hook**: MUST be enabled manually via Dashboard UI (cannot be automated)
4. **Test First**: Always test with `test-jwt-token.js` before deploying to Flutter app

---

## 🆘 Troubleshooting

### Migration fails with "syntax error"
- Check you're using **port 5432** (not 6543)
- Verify connection string has correct password

### Auth Hook not working
- Verify it's **ENABLED** in Dashboard
- Check function name is exactly: `custom_access_token_hook`
- Users must **RE-LOGIN** after enabling hook

### RLS blocking queries
- Check JWT token has custom claims (run test-jwt-token.js)
- Verify user has correct role, company_id, branch_id in public.users table

---

## 📞 Next Steps

After database setup is complete:

1. Update Flutter app to use new database
2. Test with different user roles (CEO, Manager, Staff)
3. Deploy to production

---

**Ready to start? Let's go!** 🚀
