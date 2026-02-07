# 🚀 DEPLOY SABOHUB NEXUS TO VERCEL - MANUAL GUIDE

## ⚠️ Vercel CLI Issue
The Vercel CLI has a bug with the current version. Use Vercel Dashboard instead.

---

## 📦 DEPLOYMENT STEPS (10 minutes)

### Step 1: Prepare Built Files
Project is already built! Files are in `dist/` folder.

### Step 2: Go to Vercel Dashboard
1. Open browser: https://vercel.com/login
2. Login with account associated with token: `C5LrAXQFX3ztnbT8bqCAqtgg`

### Step 3: Create New Project
1. Click **"Add New..."** → **"Project"**
2. Choose **"Import Git Repository"** OR **"Deploy from CLI"**

### Option A: Import from Git (Recommended)
1. If this repo is on GitHub, connect it
2. Vercel will auto-detect Vite settings

### Option B: Deploy via Dashboard Upload
1. Click "Deploy" button
2. Drag & drop the entire `sabohub-nexus` folder
3. OR upload a ZIP file

### Step 4: Configure Project Settings

**Build Settings:**
- Framework Preset: **Vite**
- Build Command: `npm run build`
- Output Directory: `dist`
- Install Command: `npm install`

**Environment Variables** (REQUIRED):
```
VITE_SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y
VITE_APP_NAME=SABOHUB  
VITE_ENVIRONMENT=production
VITE_DEBUG=false
```

### Step 5: Deploy
1. Click **"Deploy"** button
2. Wait 2-3 minutes for build
3. You'll get a URL like: `https://sabohub-nexus-xxx.vercel.app`

### Step 6: Add Custom Domain
1. Go to Project Settings → **Domains**
2. Click **"Add Domain"**
3. Enter: `hub.saboarena.com`
4. Vercel will show DNS instructions:
   ```
   Type: CNAME
   Name: hub
   Value: cname.vercel-dns.com
   ```

### Step 7: Configure DNS
1. Go to your DNS provider (Cloudflare/GoDaddy/etc.)
2. Add CNAME record:
   - **Type:** CNAME
   - **Name:** hub
   - **Target:** cname.vercel-dns.com
   - **TTL:** Auto
3. Save changes

### Step 8: Wait for DNS Propagation (15-30 mins)
1. Vercel will auto-generate SSL certificate
2. Check status at: https://dnschecker.org/#CNAME/hub.saboarena.com
3. Once propagated, visit: https://hub.saboarena.com

---

## ✅ SUCCESS CRITERIA

- ✅ Site loads at https://hub.saboarena.com
- ✅ SSL certificate active (🔒 padlock)
- ✅ Login works
- ✅ No console errors

---

## 🚨 ALTERNATIVE: Using Vercel CLI (if fixed)

```powershell
# Remove old config
Remove-Item -Path ".\.vercel" -Recurse -Force

# Deploy with archive mode (required for large projects)
npx vercel --prod --token oo1EcKsmpnbAN9bD0jBvsDQr --archive=tgz
```

---

## 📊 PROJECT INFO

**Vercel Token:** oo1EcKsmpnbAN9bD0jBvsDQr  
**Project Name:** sabohub-nexus  
**Target Domain:** hub.saboarena.com  
**Framework:** Vite + React  
**Build Output:** dist/  

---

## 🎯 QUICK LINK

https://vercel.com/new

**Just drag & drop the entire `sabohub-nexus` folder!**

---

**Status:** READY TO DEPLOY  
**Method:** Vercel Dashboard (Manual)  
**Time:** 10-15 minutes + DNS wait
