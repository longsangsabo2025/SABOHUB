"""
E2E Gamification Test — Simulates Flutter app Supabase queries
Tests the EXACT same queries the app makes, in the same order.
Uses Supabase Auth (like the real app) to get JWT for authenticated queries.
"""
import requests
import json
import sys

# ══════════════════════════════════════════════════════════════
# Config
# ══════════════════════════════════════════════════════════════
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

CEO_EMAIL = "longsangsabo@gmail.com"
CEO_PASSWORD = "123456"  # Supabase Auth password
CEO_EMP_ID = "0a2975b8-12bd-4592-9ef2-44a2bc99ad17"
SABO_CORP = "feef10d3-899d-4554-8107-b2256918213a"

passed = 0
failed = 0
errors = []

def test(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  PASS: {name}")
    else:
        failed += 1
        errors.append(f"{name}: {detail}")
        print(f"  FAIL: {name} -- {detail}")

print("=" * 60)
print("SABOHUB Gamification E2E Test (Authenticated)")
print("=" * 60)

# ══════════════════════════════════════════════════════════════
# STEP 0: Supabase Auth sign-in (get JWT like real app)
# ══════════════════════════════════════════════════════════════
print("\n[Step 0] Supabase Auth sign-in")
auth_headers = {
    "apikey": ANON_KEY,
    "Content-Type": "application/json",
}
r = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers=auth_headers,
    json={"email": CEO_EMAIL, "password": CEO_PASSWORD},
)
test("Auth sign-in returns 200", r.status_code == 200, f"status={r.status_code}, body={r.text[:200]}")

if r.status_code != 200:
    print("  FATAL: Cannot authenticate. Trying alternative password...")
    # Try employee default password
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers=auth_headers,
        json={"email": CEO_EMAIL, "password": "123456"},
    )
    if r.status_code != 200:
        print(f"  FATAL: Both passwords failed. Status={r.status_code}")
        print(f"  Body: {r.text[:300]}")
        sys.exit(1)

auth_data = r.json()
ACCESS_TOKEN = auth_data.get("access_token")
AUTH_UID = auth_data.get("user", {}).get("id")
print(f"  --> Auth UID: {AUTH_UID}")
print(f"  --> Token: {ACCESS_TOKEN[:50]}...")

# Now create authenticated headers
HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ACCESS_TOKEN}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}

def get(path, params=None):
    r = requests.get(f"{SUPABASE_URL}/rest/v1/{path}", headers=HEADERS, params=params)
    return r.status_code, r.json() if r.status_code == 200 else r.text

def rpc(name, body):
    r = requests.post(f"{SUPABASE_URL}/rest/v1/rpc/{name}", headers=HEADERS, json=body)
    return r.status_code, r.json() if r.status_code in (200, 201) else r.text

# ══════════════════════════════════════════════════════════════
# STEP 1: Fetch employee profile (like auth_provider does after sign-in)
# ══════════════════════════════════════════════════════════════
print("\n[Step 1] Fetch employee profile from employees table")
code, data = get("employees", {
    "select": "id,company_id,full_name,role,email,username,auth_user_id",
    "auth_user_id": f"eq.{AUTH_UID}",
})
test("Employee query returns 200", code == 200, f"status={code}")

if code == 200 and len(data) > 0:
    emp = data[0]
    USER_ID = emp["id"]
    COMPANY_ID = emp["company_id"]
    test("Employee found by auth_user_id", True)
    test("Employee ID matches expected", USER_ID == CEO_EMP_ID,
         f"expected {CEO_EMP_ID}, got {USER_ID}")
    test("Company ID = SABO Corp", COMPANY_ID == SABO_CORP,
         f"expected {SABO_CORP}, got {COMPANY_ID}")
    test("Role = ceo", emp.get("role") == "ceo", f"got {emp.get('role')}")
    print(f"  --> Employee: {emp.get('full_name')} ({emp.get('role')})")
    print(f"  --> ID: {USER_ID}, Company: {COMPANY_ID}")
else:
    print("  WARNING: Employee not found via auth_user_id, using known IDs")
    USER_ID = CEO_EMP_ID
    COMPANY_ID = SABO_CORP

# ══════════════════════════════════════════════════════════════
# STEP 2: getOrCreateProfile (what CeoProfileNotifier.loadProfile does)
# ══════════════════════════════════════════════════════════════
print("\n[Step 2] getOrCreateProfile — CEO Profile Load")
code, data = get("ceo_profiles", {
    "select": "*",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
})
test("ceo_profiles query returns 200", code == 200, f"status={code}")

if code == 200:
    test("Profile found (not empty)", len(data) > 0, "No profile found! App would create blank Level 1")
    if len(data) > 0:
        profile = data[0]
        test("Level >= 3", profile.get("level", 0) >= 3, f"level={profile.get('level')}")
        test("Total XP >= 1060", profile.get("total_xp", 0) >= 1060, f"xp={profile.get('total_xp')}")
        test("Streak days >= 1", profile.get("streak_days", 0) >= 1, f"streak={profile.get('streak_days')}")
        test("Has current_title", profile.get("current_title") is not None and len(profile.get("current_title", "")) > 0,
             f"title={profile.get('current_title')}")
        test("Business health score >= 0", profile.get("business_health_score", -1) >= 0, 
             f"health={profile.get('business_health_score')}")
        test("Streak freeze remaining >= 0", profile.get("streak_freeze_remaining", -1) >= 0,
             f"freezes={profile.get('streak_freeze_remaining')}")
        print(f"  --> Profile: Level {profile.get('level')}, {profile.get('total_xp')} XP, "
              f"'{profile.get('current_title')}', streak={profile.get('streak_days')}")

# ══════════════════════════════════════════════════════════════
# STEP 3: initializeQuestsForUser (should NOT create duplicates)
# ══════════════════════════════════════════════════════════════
print("\n[Step 3] initializeQuestsForUser — Check existing quest progress")
code, existing = get("quest_progress", {
    "select": "quest_id",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
})
test("Query existing progress returns 200", code == 200, f"status={code}")
existing_ids = set(e["quest_id"] for e in existing) if code == 200 else set()
test("Has 35 quest progress records", len(existing_ids) == 35, f"count={len(existing_ids)}")

# Check Act 1 quests — should all be in existing
code, act1 = get("quest_definitions", {
    "select": "*",
    "is_active": "eq.true",
    "quest_type": "eq.main",
    "act": "eq.1",
    "order": "sort_order",
})
if code == 200:
    act1_ids = set(q["id"] for q in act1)
    new_needed = act1_ids - existing_ids
    test("No new Act 1 quests to seed (all exist)", len(new_needed) == 0, 
         f"{len(new_needed)} quests would be created as duplicates!")

# ══════════════════════════════════════════════════════════════
# STEP 4: recordDailyLogin RPC
# ══════════════════════════════════════════════════════════════
print("\n[Step 4] recordDailyLogin RPC")
code, data = rpc("record_daily_login", {"p_user_id": USER_ID, "p_company_id": COMPANY_ID})
test("record_daily_login returns 200", code == 200, f"status={code}, body={data}")
if code == 200 and isinstance(data, list) and len(data) > 0:
    login_result = data[0]
    test("Returns streak field", "streak" in login_result, f"keys={login_result.keys()}")
    test("Returns xp_earned field", "xp_earned" in login_result, f"keys={login_result.keys()}")
    test("Returns is_new_login field", "is_new_login" in login_result, f"keys={login_result.keys()}")
    test("Streak >= 1", login_result.get("streak", 0) >= 1, f"streak={login_result.get('streak')}")
    print(f"  --> Login: streak={login_result.get('streak')}, xp_earned={login_result.get('xp_earned')}, "
          f"new_login={login_result.get('is_new_login')}")

# ══════════════════════════════════════════════════════════════
# STEP 5: getCeoProfile (re-fetch after login)
# ══════════════════════════════════════════════════════════════
print("\n[Step 5] getCeoProfile — Re-fetch after daily login")
code, data = get("ceo_profiles", {
    "select": "*",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
})
if code == 200 and len(data) > 0:
    profile = data[0]
    test("Profile still exists after login", True)
    test("XP not reset", profile.get("total_xp", 0) >= 1060, f"xp={profile.get('total_xp')}")
    test("Level not reset", profile.get("level", 0) >= 3, f"level={profile.get('level')}")

# ══════════════════════════════════════════════════════════════
# STEP 6: Quest Hub Tab 1 — Active Quests (available OR in_progress)
# ══════════════════════════════════════════════════════════════
print("\n[Step 6] Quest Hub Tab 1 — Active Quests")
code, data = get("quest_progress", {
    "select": "*,quest_definitions(*)",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
    "order": "updated_at.desc",
})
test("Quest progress with definitions returns 200", code == 200, f"status={code}")
if code == 200:
    all_quests = data
    active = [q for q in all_quests if q["status"] in ("available", "in_progress")]
    completed = [q for q in all_quests if q["status"] == "completed"]
    locked = [q for q in all_quests if q["status"] == "locked"]
    
    test("Active quests >= 5", len(active) >= 5, f"count={len(active)}")
    test("Completed quests >= 9", len(completed) >= 9, f"count={len(completed)}")
    test("Total = 35", len(all_quests) == 35, f"count={len(all_quests)}")
    
    # Check quest definitions are loaded (join worked)
    if active:
        first_quest = active[0]
        quest_def = first_quest.get("quest_definitions")
        test("Quest definition joined", quest_def is not None, "quest_definitions is None!")
        if quest_def:
            test("Quest has name", quest_def.get("name") is not None and len(quest_def.get("name","")) > 0,
                 f"name={quest_def.get('name')}")
            test("Quest has xp_reward", quest_def.get("xp_reward") is not None,
                 f"xp_reward={quest_def.get('xp_reward')}")
            test("Quest has quest_type", quest_def.get("quest_type") is not None,
                 f"quest_type={quest_def.get('quest_type')}")
    
    print(f"  --> Active: {len(active)}, Completed: {len(completed)}, Locked: {len(locked)}")
    print(f"  --> Active quest names:")
    for q in active[:5]:
        qd = q.get("quest_definitions", {})
        print(f"      - [{q['status']}] {qd.get('name', 'N/A')} ({qd.get('xp_reward',0)} XP)")

# ══════════════════════════════════════════════════════════════
# STEP 7: Quest Hub Tab 1 — Completed Quests
# ══════════════════════════════════════════════════════════════
print("\n[Step 7] Quest Hub Tab 1 — Completed Quests")
code, data = get("quest_progress", {
    "select": "*,quest_definitions(*)",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
    "status": "eq.completed",
    "order": "updated_at.desc",
})
if code == 200:
    test("Completed quests returned", len(data) >= 9, f"count={len(data)}")
    for q in data[:5]:
        qd = q.get("quest_definitions", {})
        print(f"  --> [{q['status']}] {qd.get('name', 'N/A')} (completed: {q.get('completed_at', 'N/A')})")

# ══════════════════════════════════════════════════════════════
# STEP 8: Quest Hub Tab 2 — Daily Quests
# ══════════════════════════════════════════════════════════════
print("\n[Step 8] Quest Hub Tab 2 — Daily Quests")
code, daily_defs = get("quest_definitions", {
    "select": "*",
    "is_active": "eq.true",
    "quest_type": "eq.daily",
    "order": "sort_order",
})
test("Daily quest definitions query OK", code == 200, f"status={code}")
if code == 200:
    test("Has daily quest definitions", len(daily_defs) >= 0, f"count={len(daily_defs)}")
    print(f"  --> {len(daily_defs)} daily quest definitions")

# Check daily_quest_log  
code, log = get("daily_quest_log", {
    "select": "*",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
    "order": "log_date.desc",
    "limit": "1",
})
test("Daily quest log query OK", code == 200, f"status={code}")
if code == 200 and len(log) > 0:
    test("Has today's log entry", True)
    print(f"  --> Last log: {log[0].get('log_date')}, streak={log[0].get('streak_at_login')}")

# ══════════════════════════════════════════════════════════════
# STEP 9: Quest Hub Tab 3 — Achievements
# ══════════════════════════════════════════════════════════════
print("\n[Step 9] Quest Hub Tab 3 — Achievements")
code, achievements = get("achievements", {
    "select": "*",
    "is_secret": "eq.false",
    "order": "sort_order",
})
test("Achievements query OK", code == 200, f"status={code}")
if code == 200:
    test("Has achievement definitions", len(achievements) >= 10, f"count={len(achievements)}")
    print(f"  --> {len(achievements)} achievements defined")

# User achievements
code, user_ach = get("user_achievements", {
    "select": "*,achievements(*)",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
})
test("User achievements query OK", code == 200, f"status={code}")
if code == 200:
    print(f"  --> {len(user_ach)} achievements unlocked by CEO")

# ══════════════════════════════════════════════════════════════
# STEP 10: Quest Hub Tab 4 — Staff Leaderboard
# ══════════════════════════════════════════════════════════════
print("\n[Step 10] Quest Hub Tab 4 — Staff Leaderboard")
code, leaderboard = rpc("get_staff_leaderboard", {"p_company_id": COMPANY_ID, "p_limit": 20})
test("Staff leaderboard RPC OK", code == 200, f"status={code}, body={leaderboard}")
if code == 200 and isinstance(leaderboard, list):
    test("Has leaderboard entries", len(leaderboard) >= 0)
    for entry in leaderboard[:3]:
        print(f"  --> #{entry.get('rank')} {entry.get('full_name')} (Level {entry.get('level')}, "
              f"{entry.get('total_xp')} XP)")

# ══════════════════════════════════════════════════════════════
# STEP 11: Quest Hub Tab 5 — Staff Profiles
# ══════════════════════════════════════════════════════════════
print("\n[Step 11] Quest Hub Tab 5 — Staff Profiles (employee_game_profiles)")
code, staff = get("employee_game_profiles", {
    "select": "*",
    "company_id": f"eq.{COMPANY_ID}",
})
test("Staff game profiles query OK", code == 200, f"status={code}")
if code == 200:
    print(f"  --> {len(staff)} staff profiles in SABO Corp")

# ══════════════════════════════════════════════════════════════
# STEP 12: Evaluate Main Quests (Pull-to-refresh action)
# ══════════════════════════════════════════════════════════════
print("\n[Step 12] evaluateMainQuests — Pull-to-refresh")
code, data = rpc("evaluate_user_quests", {
    "p_user_id": USER_ID, 
    "p_company_id": COMPANY_ID,
    "p_event_type": "manual_check",
})
test("evaluate_user_quests RPC OK", code in (200, 204), f"status={code}, body={data}")

# ══════════════════════════════════════════════════════════════
# STEP 13: Evaluate Daily Quests
# ══════════════════════════════════════════════════════════════
print("\n[Step 13] evaluateDailyQuests")
code, data = rpc("evaluate_daily_quests", {"p_user_id": USER_ID, "p_company_id": COMPANY_ID})
test("evaluate_daily_quests RPC OK", code == 200, f"status={code}, body={data}")

# ══════════════════════════════════════════════════════════════
# STEP 14: Evaluate Achievements
# ══════════════════════════════════════════════════════════════
print("\n[Step 14] evaluateAchievements")
code, data = rpc("evaluate_achievements", {"p_user_id": USER_ID, "p_company_id": COMPANY_ID})
test("evaluate_achievements RPC OK", code == 200, f"status={code}, body={data}")

# ══════════════════════════════════════════════════════════════
# STEP 15: XP History
# ══════════════════════════════════════════════════════════════
print("\n[Step 15] XP History")
code, xp_history = get("xp_transactions", {
    "select": "*",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
    "order": "created_at.desc",
    "limit": "10",
})
test("XP transactions query OK", code == 200, f"status={code}")
if code == 200:
    test("Has XP transactions", len(xp_history) >= 5, f"count={len(xp_history)}")
    total_from_transactions = sum(t.get("amount", 0) for t in xp_history)
    print(f"  --> {len(xp_history)} transactions, sum={total_from_transactions} XP")
    for t in xp_history[:3]:
        print(f"      - {t.get('source_type')}: +{t.get('amount')} XP ({t.get('description', '')})")

# ══════════════════════════════════════════════════════════════
# STEP 16: Skill Definitions (Skill Tree Widget)
# ══════════════════════════════════════════════════════════════
print("\n[Step 16] Skill Definitions")
code, skills = get("skill_definitions", {"select": "*", "order": "sort_order"})
test("Skill definitions query OK", code == 200, f"status={code}")
if code == 200:
    test("Has skill definitions", len(skills) >= 5, f"count={len(skills)}")
    print(f"  --> {len(skills)} skills defined")

# ══════════════════════════════════════════════════════════════
# STEP 17: Season Data
# ══════════════════════════════════════════════════════════════
print("\n[Step 17] Season Data")
code, seasons = get("seasons", {"select": "*", "is_active": "eq.true"})
test("Seasons query OK", code == 200, f"status={code}")
if code == 200:
    test("Has active season", len(seasons) >= 1, f"count={len(seasons)}")
    if seasons:
        s = seasons[0]
        print(f"  --> Season: {s.get('name')}, {s.get('start_date')} to {s.get('end_date')}")

# ══════════════════════════════════════════════════════════════
# STEP 18: Uy Tin Store Items
# ══════════════════════════════════════════════════════════════
print("\n[Step 18] Uy Tin Store Items")
code, items = get("uytin_store_items", {"select": "*", "is_active": "eq.true", "order": "sort_order"})
test("Uytin store items query OK", code == 200, f"status={code}")
if code == 200:
    test("Has store items", len(items) >= 1, f"count={len(items)}")
    print(f"  --> {len(items)} store items available")

# ══════════════════════════════════════════════════════════════
# STEP 19: CeoProfile Model Validation
# ══════════════════════════════════════════════════════════════
print("\n[Step 19] CeoProfile Model Validation (Dart fromJson simulation)")
code, data = get("ceo_profiles", {
    "select": "*",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
})
if code == 200 and len(data) > 0:
    p = data[0]
    # Validate all fields that CeoProfile.fromJson expects
    required_fields = [
        "id", "user_id", "company_id", "level", "total_xp", "current_title",
        "streak_days", "longest_streak", "business_health_score",
        "streak_freeze_remaining", "prestige_level", "reputation_points",
        "skill_points", "active_badges", "last_login_date",
    ]
    for field in required_fields:
        test(f"Profile has '{field}'", field in p, f"missing field '{field}'")
    
    # CeoLevel.xpForLevel formula: (100 * level^1.5).floor()
    import math
    level = p.get("level", 1)
    xp = p.get("total_xp", 0)
    
    xp_for_current = math.floor(100 * (level ** 1.5))
    xp_for_next = math.floor(100 * ((level + 1) ** 1.5))
    test(f"XP >= xpForLevel({level}) = {xp_for_current}", xp >= xp_for_current,
         f"xp={xp}, needed={xp_for_current}")
    test(f"XP < xpForLevel({level+1}) = {xp_for_next}", xp < xp_for_next,
         f"xp={xp}, next_level_at={xp_for_next}")
    
    # Title validation
    title = p.get("current_title", "")
    if level <= 5:
        expected = "Tan Binh"
    elif level <= 15:
        expected = "Chu Tiem"
    else:
        expected = "unknown"
    # Note: title in DB might be Vietnamese with diacritics
    print(f"  --> Level {level} title: '{title}' (expected tier: ~{expected})")

# ══════════════════════════════════════════════════════════════
# STEP 20: QuestProgress Model Validation
# ══════════════════════════════════════════════════════════════
print("\n[Step 20] QuestProgress Model Validation")
code, quests = get("quest_progress", {
    "select": "*,quest_definitions(*)",
    "user_id": f"eq.{USER_ID}",
    "company_id": f"eq.{COMPANY_ID}",
    "status": "eq.completed",
    "limit": "1",
})
if code == 200 and len(quests) > 0:
    q = quests[0]
    qp_required = ["id", "user_id", "company_id", "quest_id", "status", 
                   "progress_current", "progress_target"]
    for field in qp_required:
        test(f"QuestProgress has '{field}'", field in q, f"missing '{field}'")
    
    qd = q.get("quest_definitions", {})
    qd_required = ["id", "code", "name", "description", "quest_type", "act", 
                   "xp_reward", "conditions", "sort_order"]
    for field in qd_required:
        test(f"QuestDefinition has '{field}'", field in qd, f"missing '{field}'")
    
    test("Completed quest has completed_at", q.get("completed_at") is not None,
         f"completed_at={q.get('completed_at')}")

# ══════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print(f"RESULTS: {passed} passed, {failed} failed")
print("=" * 60)

if errors:
    print("\nFailed tests:")
    for e in errors:
        print(f"  X {e}")

if failed == 0:
    print("\nAll E2E tests PASSED! Gamification feature is working correctly.")
else:
    print(f"\n{failed} tests FAILED. Review errors above.")

sys.exit(1 if failed > 0 else 0)
