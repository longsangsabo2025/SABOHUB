"""
SABOHUB Gamification — Activate for CEO longsangsabo@gmail.com
Elon Mode: Ship it. Measure it. Iterate.
"""
import psycopg2, json, math
from datetime import datetime, date, timedelta

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com", port=6543,
    dbname="postgres", user="postgres.dqddxowyikefqcdiioyh", password="Acookingoil123"
)
conn.autocommit = False
cur = conn.cursor()

CEO_EMAIL = "longsangsabo@gmail.com"
ENTERTAINMENT_TYPES = {'billiards', 'restaurant', 'hotel', 'cafe', 'retail'}
DISTRIBUTION_TYPES = {'distribution', 'manufacturing'}

print("=" * 70)
print("  SABOHUB GAMIFICATION — CEO ACTIVATION")
print("  Elon Mode: Ship > Measure > Iterate")
print("=" * 70)

# === STEP 1: Find CEO ===
print("\n[1] Finding CEO...")
cur.execute("""
    SELECT e.id, e.full_name, e.email, e.role, e.company_id, e.auth_user_id
    FROM employees e WHERE e.email = %s
""", (CEO_EMAIL,))
ceo = cur.fetchone()
if not ceo:
    print(f"  FAIL: CEO not found: {CEO_EMAIL}"); exit()

ceo_id, ceo_name, ceo_email, ceo_role, ceo_company_id, ceo_auth = ceo
print(f"  OK: {ceo_name} ({ceo_email}) role={ceo_role}")
print(f"      ID: {ceo_id}")

cur.execute("SELECT id, name, business_type FROM companies ORDER BY name")
all_companies = cur.fetchall()
company_ids = [c[0] for c in all_companies]
has_dist = any(c[2] in DISTRIBUTION_TYPES for c in all_companies)
has_ent = any(c[2] in ENTERTAINMENT_TYPES for c in all_companies)

print(f"\n  Companies ({len(all_companies)}):")
for c in all_companies:
    tag = "[DIST]" if c[2] in DISTRIBUTION_TYPES else "[ENT]" if c[2] in ENTERTAINMENT_TYPES else "[CORP]"
    print(f"    {tag} {c[1]} ({c[2]})")

# === STEP 2: CEO Game Profile ===
print("\n[2] CEO Game Profile...")
cur.execute("SELECT id, level, total_xp, current_title, streak_days FROM ceo_profiles WHERE user_id = %s", (ceo_id,))
profile = cur.fetchone()

if profile:
    print(f"  EXISTS: Lv{profile[1]}, {profile[2]}XP, \"{profile[3]}\", streak={profile[4]}")
else:
    print("  CREATING new profile...")
    cur.execute("""
        INSERT INTO ceo_profiles (user_id, company_id, level, total_xp, current_title, 
            active_badges, streak_days, longest_streak, last_login_date, streak_freeze_remaining,
            reputation_points, skill_points, skill_tree, business_health_score, prestige_level, prestige_bonuses)
        VALUES (%s, %s, 1, 0, 'Tan Binh', '{}', 0, 0, %s, 3, 0, 0, '{}', 0, 0, '{}')
        RETURNING level, total_xp, current_title
    """, (ceo_id, ceo_company_id, date.today()))
    p = cur.fetchone()
    conn.commit()
    print(f"  CREATED: Lv{p[0]}, {p[1]}XP, \"{p[2]}\"")

# === STEP 3: Business Metrics ===
print("\n[3] Scanning business data...")
m = {}
qs = {
    'companies': ("SELECT COUNT(*) FROM companies", []),
    'branches': ("SELECT COUNT(*) FROM branches WHERE company_id = ANY(%s)", [company_ids]),
    'employees': ("SELECT COUNT(*) FROM employees WHERE company_id = ANY(%s) AND is_active = true", [company_ids]),
    'customers': ("SELECT COUNT(*) FROM customers WHERE company_id = ANY(%s)", [company_ids]),
    'total_orders': ("SELECT COUNT(*) FROM sales_orders WHERE company_id = ANY(%s)", [company_ids]),
    'completed_orders': ("SELECT COUNT(*) FROM sales_orders WHERE company_id = ANY(%s) AND status = 'completed'", [company_ids]),
    'tasks_created': ("SELECT COUNT(*) FROM tasks WHERE created_by = %s", [ceo_id]),
    'tasks_assigned': ("SELECT COUNT(*) FROM tasks WHERE created_by = %s AND assigned_to IS NOT NULL", [ceo_id]),
    'warehouses': ("SELECT COUNT(*) FROM warehouses WHERE company_id = ANY(%s)", [company_ids]),
    'products': ("SELECT COUNT(*) FROM products WHERE company_id = ANY(%s)", [company_ids]),
    'deliveries_done': ("SELECT COUNT(*) FROM deliveries WHERE company_id = ANY(%s) AND status = 'completed'", [company_ids]),
    'tables': ("SELECT COUNT(*) FROM tables WHERE company_id = ANY(%s)", [company_ids]),
    'sessions_done': ("SELECT COUNT(*) FROM table_sessions WHERE company_id = ANY(%s) AND status = 'completed'", [company_ids]),
    'menu_items': ("SELECT COUNT(*) FROM menu_items WHERE company_id = ANY(%s)", [company_ids]),
    'pnl_months': ("SELECT COUNT(*) FROM monthly_pnl WHERE company_id = ANY(%s)", [company_ids]),
    'payments': ("SELECT COUNT(*) FROM payments WHERE company_id = ANY(%s)", [company_ids]),
}
for k, (sql, params) in qs.items():
    try:
        cur.execute(sql, params)
        m[k] = cur.fetchone()[0]
    except:
        conn.rollback()
        m[k] = 0

print(f"\n  Business Metrics:")
for k, v in m.items():
    icon = "+" if v > 0 else " "
    print(f"    {icon} {k:20s} = {v}")

# === STEP 4: Init Quest Progress ===
print("\n[4] Initializing quests...")
cur.execute("""
    SELECT id, code, name, quest_type, act, business_type, conditions, xp_reward
    FROM quest_definitions WHERE is_active = true ORDER BY act NULLS FIRST, sort_order
""")
all_quests = cur.fetchall()

cur.execute("SELECT quest_id FROM quest_progress WHERE user_id = %s", (ceo_id,))
existing = {r[0] for r in cur.fetchall()}

added = 0
for q_id, code, name, qt, act, biz, conds, xp in all_quests:
    if q_id in existing:
        continue
    if biz == 'distribution' and not has_dist:
        continue
    if biz == 'entertainment' and not has_ent:
        continue
    
    status = 'available' if (qt in ('daily', 'weekly') or act == 1 or act is None) else 'locked'
    target = 1
    if conds and isinstance(conds, dict):
        target = conds.get('value', 1)
    
    cur.execute("""
        INSERT INTO quest_progress (user_id, company_id, quest_id, status, progress_current, progress_target, progress_data)
        VALUES (%s, %s, %s, %s, 0, %s, '{}') ON CONFLICT DO NOTHING
    """, (ceo_id, ceo_company_id, q_id, status, target))
    added += 1

conn.commit()
print(f"  Added {added} quest records")

# === STEP 5: Auto-Evaluate ===
print("\n[5] Auto-evaluating quests against REAL data...")
cur.execute("""
    SELECT qp.id, qp.quest_id, qd.code, qd.name, qd.conditions, qd.xp_reward, qd.quest_type, qd.act, qd.reputation_reward
    FROM quest_progress qp JOIN quest_definitions qd ON qp.quest_id = qd.id
    WHERE qp.user_id = %s AND qp.status IN ('available', 'in_progress')
    ORDER BY qd.act NULLS FIRST, qd.sort_order
""", (ceo_id,))
avail = cur.fetchall()

done_quests = []
tot_xp = 0
tot_rep = 0

def check(code, conds):
    c = (code or '').lower()
    # Act I
    if c == 'act1_khai_sinh': return m['companies'] >= 1
    if c == 'act1_xay_doanh_trai': return m['branches'] >= 1
    if c == 'act1_chieu_mo': return m['employees'] >= 3
    if c == 'act1_phan_binh': return m['employees'] >= 3
    if c == 'act1_menh_lenh': return m['tasks_created'] >= 5
    if c == 'act1_ngay_dau': return False
    if c == 'act1_boss': return False
    # Act II Distribution
    if c == 'act2d_kho_bau': return m['warehouses'] >= 1 and m['products'] >= 20
    if c == 'act2d_khach_vang': return m['customers'] >= 10
    if c == 'act2d_don_hang': return m['completed_orders'] >= 1
    if c == 'act2d_tua_lua': return m['deliveries_done'] >= 5
    if c == 'act2d_giao_hang_50': return m['deliveries_done'] >= 50
    if c == 'act2d_can_bang': return False
    if c == 'act2d_khach_vip': return False
    if c == 'act2d_boss': return False
    # Act II Entertainment
    if c == 'act2e_bay_binh': return m['tables'] >= 5
    if c == 'act2e_khai_truong': return m['sessions_done'] >= 10
    if c == 'act2e_dau_bep': return m['menu_items'] >= 15
    if c == 'act2e_phuc_vu': return m['sessions_done'] >= 50
    if c == 'act2e_boss': return False
    # Act III
    if c == 'act3_chi_nhanh': return m['branches'] >= 2
    if c == 'act3_doi_quan': return m['employees'] >= 20
    if c == 'act3_tai_chinh': return False
    if c == 'act3_da_nang': return False
    if c == 'act3_boss': return False
    # Act IV
    if c == 'act4_de_che': return m['branches'] >= 3
    if c == 'act4_skill_master': return False
    if c == 'act4_nha_dau_tu': return False
    if c == 'act4_huyen_thoai': return False
    if c == 'act4_boss_final': return False
    # Generic
    if conds and isinstance(conds, dict):
        ct = conds.get('type', '')
        tb = conds.get('table', '')
        val = conds.get('value', 0)
        if ct == 'count':
            mapping = {'employees': m['employees'], 'branches': m['branches'], 'companies': m['companies'],
                       'sales_orders': m['completed_orders'], 'customers': m['customers'], 'tasks': m['tasks_created'],
                       'warehouses': m['warehouses'], 'products': m['products'], 'deliveries': m['deliveries_done'],
                       'tables': m['tables'], 'table_sessions': m['sessions_done'], 'menu_items': m['menu_items'], 'payments': m['payments']}
            for key, metric in mapping.items():
                if key in tb: return metric >= val
        if ct == 'exists':
            return m.get('companies', 0) >= 1
    return False

for qp_id, quest_id, code, name, conds, xp, qt, act, rep in avail:
    rep = rep or 0
    if check(code, conds):
        cur.execute("""
            UPDATE quest_progress SET status = 'completed', completed_at = NOW(), progress_current = progress_target,
                progress_data = '{"auto_evaluated": true, "source": "ceo_activation"}' WHERE id = %s
        """, (qp_id,))
        cur.execute("""
            INSERT INTO xp_transactions (user_id, company_id, amount, multiplier, final_amount, source_type, source_id, description)
            VALUES (%s, %s, %s, 1.0, %s, 'quest', %s, %s)
        """, (ceo_id, ceo_company_id, xp, xp, str(quest_id), f'Quest: {name}'))
        done_quests.append((name, xp, rep, qt, act))
        tot_xp += xp
        tot_rep += rep

conn.commit()

if done_quests:
    print(f"\n  COMPLETED {len(done_quests)} quests:")
    print(f"  {'_' * 58}")
    for name, xp, rep, qt, act in done_quests:
        tag = f"Act{act}" if act else qt
        print(f"    [{tag:7s}] {name:35s} +{xp:4d}XP" + (f" +{rep}Rep" if rep else ""))
    print(f"  {'_' * 58}")
    print(f"    TOTAL: +{tot_xp} XP, +{tot_rep} Reputation")
else:
    print("  No quests auto-completed")

# === STEP 6: Update Level ===
print(f"\n[6] Updating level...")
cur.execute("SELECT total_xp, reputation_points FROM ceo_profiles WHERE user_id = %s", (ceo_id,))
old_xp, old_rep = cur.fetchone()
old_xp = old_xp or 0; old_rep = old_rep or 0
new_xp = old_xp + tot_xp
new_rep = old_rep + tot_rep

lvl = 1
for l in range(1, 101):
    if new_xp >= math.floor(100 * (l ** 1.5)):
        lvl = l
    else:
        break

title_map = [(5, "Tan Binh"), (15, "Chu Tiem"), (30, "Ong Chu"), (50, "Doanh Nhan"), (75, "Tuong Quan"), (99, "De Vuong"), (100, "Huyen Thoai")]
title = "Tan Binh"
for mx, t in title_map:
    if lvl <= mx:
        title = t; break

sp = max(0, (lvl - 20) // 5 + 1) if lvl >= 20 else 0

cur.execute("""
    UPDATE ceo_profiles SET total_xp = %s, level = %s, current_title = %s, reputation_points = %s, 
        skill_points = %s, last_login_date = %s, updated_at = NOW() WHERE user_id = %s
""", (new_xp, lvl, title, new_rep, sp, date.today(), ceo_id))
conn.commit()

nxt = math.floor(100 * ((lvl + 1) ** 1.5))
print(f"  XP:    {old_xp} -> {new_xp} (+{tot_xp})")
print(f"  Level: {lvl} \"{title}\"")
print(f"  Next:  {nxt} XP (need {nxt - new_xp} more)")
print(f"  Rep:   {new_rep}, Skills: {sp}")

# === STEP 7: Daily Login ===
print(f"\n[7] Daily login & streak...")
today = date.today()
cur.execute("SELECT log_date, streak_count FROM daily_quest_log WHERE user_id = %s AND log_date = %s", (ceo_id, today))
if cur.fetchone():
    print("  Already logged today")
else:
    cur.execute("SELECT streak_count FROM daily_quest_log WHERE user_id = %s AND log_date = %s", (ceo_id, today - timedelta(days=1)))
    ylog = cur.fetchone()
    streak = (ylog[0] + 1) if ylog else 1
    cur.execute("""
        INSERT INTO daily_quest_log (user_id, company_id, log_date, quests_completed, combo_completed, xp_earned, streak_count, logged_in)
        VALUES (%s, %s, %s, '{}', false, 10, %s, true) ON CONFLICT DO NOTHING
    """, (ceo_id, ceo_company_id, today, streak))
    cur.execute("UPDATE ceo_profiles SET streak_days = %s, longest_streak = GREATEST(longest_streak, %s) WHERE user_id = %s", (streak, streak, ceo_id))
    cur.execute("""
        INSERT INTO xp_transactions (user_id, company_id, amount, multiplier, final_amount, source_type, source_id, description)
        VALUES (%s, %s, 10, 1.0, 10, 'login', %s, 'CEO Co Tam - daily login')
    """, (ceo_id, ceo_company_id, str(today)))
    cur.execute("UPDATE ceo_profiles SET total_xp = total_xp + 10 WHERE user_id = %s", (ceo_id,))
    conn.commit()
    print(f"  Login OK! Streak: {streak}, +10 XP")

# === STEP 8: Unlock acts ===
print(f"\n[8] Quest unlocks...")
for af, at, th in [(1, 2, 0.6), (2, 3, 0.5), (3, 4, 0.5)]:
    cur.execute("""
        SELECT COUNT(*) FILTER (WHERE qp.status = 'completed'), COUNT(*)
        FROM quest_progress qp JOIN quest_definitions qd ON qp.quest_id = qd.id
        WHERE qp.user_id = %s AND qd.act = %s
    """, (ceo_id, af))
    d, t = cur.fetchone()
    pct = d/t if t > 0 else 0
    status_str = f"Act{af}: {d}/{t} ({pct:.0%})"
    if pct >= th:
        cur.execute("""
            UPDATE quest_progress qp SET status = 'available'
            FROM quest_definitions qd
            WHERE qp.quest_id = qd.id AND qp.user_id = %s AND qd.act = %s AND qp.status = 'locked'
        """, (ceo_id, at))
        u = cur.rowcount; conn.commit()
        if u > 0:
            status_str += f" -> UNLOCKED {u} Act{at} quests!"
    print(f"  {status_str}")

# === STEP 9: Staff profiles ===
print(f"\n[9] Staff gamification...")
cur.execute("""
    SELECT e.id, e.full_name, e.role, e.company_id
    FROM employees e WHERE e.company_id = ANY(%s::uuid[]) AND e.is_active = true AND e.id != %s
""", (company_ids, ceo_id))
staff = cur.fetchall()
np = 0
for eid, ename, erole, ecomp in staff:
    cur.execute("SELECT id FROM employee_game_profiles WHERE employee_id = %s", (eid,))
    if not cur.fetchone():
        cur.execute("""
            INSERT INTO employee_game_profiles (employee_id, company_id, level, total_xp, current_title,
                attendance_score, task_score, punctuality_score, overall_rating, streak_days, longest_streak, badges, monthly_xp)
            VALUES (%s, %s, 1, 0, 'Recruit', 0, 0, 0, 0, 0, 0, '{}', 0) ON CONFLICT DO NOTHING
        """, (eid, ecomp))
        np += 1
        print(f"    + {ename} ({erole})")
conn.commit()
print(f"  Staff: {len(staff)}, new profiles: {np}")

# === FINAL REPORT ===
cur.execute("SELECT level, total_xp, current_title, streak_days, reputation_points, skill_points, prestige_level FROM ceo_profiles WHERE user_id = %s", (ceo_id,))
f = cur.fetchone()
cur.execute("SELECT qp.status, COUNT(*) FROM quest_progress qp WHERE qp.user_id = %s GROUP BY qp.status ORDER BY qp.status", (ceo_id,))
fp = cur.fetchall()
cur.execute("SELECT COUNT(*), COALESCE(SUM(final_amount), 0) FROM xp_transactions WHERE user_id = %s", (ceo_id,))
txc, txt = cur.fetchone()

print(f"""
{'=' * 70}
  ACTIVATION COMPLETE
{'=' * 70}

  CEO:      {ceo_name} ({ceo_email})
  Level:    {f[0]} - "{f[2]}"
  XP:       {f[1]}
  Streak:   {f[3]} days
  Rep:      {f[4]}
  Skills:   {f[5]}
  Prestige: {f[6]}
  
  Quests:""")
tq = 0
for s, c in fp:
    e = {"completed": "+", "available": "o", "in_progress": "~", "locked": "-"}.get(s, "?")
    print(f"    [{e}] {s:15s} {c}")
    tq += c

print(f"    Total: {tq} quests, {txc} XP transactions ({txt} XP)")
print(f"""
  Business: {m['companies']} companies, {m['branches']} branches, {m['employees']} employees
            {m['total_orders']} orders, {m['deliveries_done']} deliveries, {m['tables']} tables
            {m['pnl_months']} months P&L

{'=' * 70}
  CEO can now open Quest Hub: /quest-hub
  Game Profile: /ceo-game-profile
{'=' * 70}""")

cur.close(); conn.close()
