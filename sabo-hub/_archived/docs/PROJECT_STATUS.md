# PROJECT STATUS — SABOHUB (Flutter)
> Operations Management — HR, KPI, Finance, Distribution
> Last updated: 2026-02-25

---

## QUICK INFO

| Field | Value |
|-------|-------|
| **URL** | Chưa deploy (mobile app) |
| **Stack** | Flutter 3.5 + Riverpod + GoRouter + Supabase |
| **Supabase** | `diexsbzqwsbpilsymnfb` (shared) |
| **Files** | 447+ Dart files |
| **Completion** | **87%** |
| **Revenue** | ❌ $0 — internal tool, chưa deploy |

---

## CHECKLIST → 100%

### ✅ Core (DONE)
- [x] Flutter 3.5 + Riverpod + GoRouter + Supabase
- [x] 7 role-based dashboards
- [x] Distribution module (85-90%)
- [x] Entertainment module (85%)
- [x] Offline sync fixed (5 methods → Supabase direct)
- [x] Cache toJson() fixed (OdoriProduct, SalesOrder, Delivery)
- [x] .env configured for shared Supabase
- [x] 0 flutter analyze errors

### ⏳ Manufacturing Module (70%)
- [x] 8 pages (suppliers, materials, BOM, POs, production, payables)
- [x] Full service layer
- [x] 11 model classes with toJson/fromJson
- [ ] Testing + edge cases
- [ ] Real data integration

### ⬜ Map/GPS
- [x] Fully implemented (geolocator, 5 map pages, 4 widgets, driver module)
- [ ] **Google Maps API key** in AndroidManifest.xml + iOS config
- [ ] Test GPS tracking on real device

### ⬜ Payment Integration
- [x] VNPay/MoMo env templates exist
- [x] Payment labels in UI
- [ ] Actual payment SDK integration
- [ ] Payment flow testing

### ⬜ Build & Deploy
- [ ] Flutter build iOS (needs Apple dev account)
- [ ] Flutter build Android APK/AAB
- [ ] Test on physical devices
- [ ] Internal beta deployment (TestFlight / Internal Track)
- [ ] Codemagic CI/CD pipeline (env groups set up)

### ⬜ Remaining for 100%
- [ ] Manufacturing module testing
- [ ] Google Maps API key
- [ ] Payment integration
- [ ] Build for iOS + Android
- [ ] Beta testing with real users
- [ ] First production deploy

---

## BLOCKERS

| Blocker | Owner | Impact | ETA |
|---------|:-----:|--------|:---:|
| No Google Maps API key | CEO | Map features broken | 10 min |
| No physical device testing | CEO | Unknown mobile bugs | 1 day |
| Codemagic secrets removed | CTO | CI/CD broken until env groups set | 10 min |

---

## RECENT CHANGES

| Date | Change |
|------|--------|
| 2026-02-25 | Offline sync 5 methods fixed |
| 2026-02-25 | Cache toJson() added to 3 models |
| 2026-02-25 | .env → shared Supabase |
| 2026-02-25 | Manufacturing module assessed (70%) |
| 2026-02-25 | codemagic.yaml secrets → env groups |
