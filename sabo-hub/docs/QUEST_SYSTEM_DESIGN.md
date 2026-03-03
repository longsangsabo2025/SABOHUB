# SABOHUB RPG — Hệ Thống Nhiệm Vụ CEO

> **Triết lý:** "Chơi game = Vận hành thật."  
> Mỗi quest map trực tiếp vào hành động kinh doanh thực tế.  
> CEO hoàn thành quest = doanh nghiệp vận hành tốt hơn. Không có quest rác.

---

## 1. Hệ Thống Cấp Độ CEO (CEO Level System)

| Level | Danh hiệu | XP cần | Mô tả |
|-------|-----------|--------|--------|
| 1-5 | **Tân Binh** (Rookie) | 0-500 | Mới setup, đang học hệ thống |
| 6-15 | **Chủ Tiệm** (Shop Owner) | 500-3,000 | Vận hành cơ bản ổn định |
| 16-30 | **Ông Chủ** (Boss) | 3,000-10,000 | Quản lý nhiều branch, nhân sự |
| 31-50 | **Doanh Nhân** (Entrepreneur) | 10,000-30,000 | Tối ưu tài chính, mở rộng |
| 51-75 | **Tướng Quân** (General) | 30,000-80,000 | Multi-business, hệ thống tự chạy |
| 76-99 | **Đế Vương** (Emperor) | 80,000-200,000 | Đế chế kinh doanh |
| 100 | **Huyền Thoại** (Legend) | 200,000+ | Hall of Fame |

### XP Curve Formula
```
xp_for_level(n) = floor(100 * n^1.5)
```
Tăng dần theo đường cong — level đầu dễ, càng cao càng khó.

---

## 2. Chuỗi Nhiệm Vụ Chính (Main Quest Lines)

### Act I — "Khởi Nghiệp" (The Foundation)
*Unlock: Khi tạo tài khoản CEO*

| Quest | Tên | Hành động thực tế | XP | Phần thưởng |
|-------|-----|-------------------|-----|-------------|
| 1.1 | **Khai Sinh** | Tạo company, điền đầy đủ thông tin | 50 | Badge "Founder" |
| 1.2 | **Xây Doanh Trại** | Tạo branch đầu tiên | 50 | Unlock HR module |
| 1.3 | **Chiêu Mộ Chiến Binh** | Mời 3 nhân viên đầu tiên | 100 | Badge "Recruiter" |
| 1.4 | **Phân Binh Bố Trận** | Tạo phòng ban, gán role cho nhân viên | 100 | Unlock Attendance |
| 1.5 | **Ngày Đầu Tiên** | Tất cả nhân viên check-in thành công 1 ngày | 150 | Unlock Tasks module |
| 1.6 | **Mệnh Lệnh Đầu Tiên** | Tạo và giao 5 task cho nhân viên | 100 | Badge "Commander" |

**🏰 Boss Challenge Act I:** *"Tuần Lễ Hoàn Hảo"*  
→ 7 ngày liên tiếp: 100% attendance, 100% task completion rate  
→ **+500 XP, Title "Người Khai Sáng"**

---

### Act II — "Vận Hành" (Operations Mastery)
*Unlock: Hoàn thành Act I*

#### 🚚 Nhánh Phân Phối (Distribution Path)
| Quest | Tên | Hành động thực tế | XP |
|-------|-----|-------------------|-----|
| 2D.1 | **Kho Báu Đầu Tiên** | Tạo warehouse, nhập 20 sản phẩm | 150 |
| 2D.2 | **Khách Hàng Vàng** | Thêm 10 khách hàng đầu tiên | 150 |
| 2D.3 | **Đơn Hàng Xử Nữ** | Tạo và hoàn thành sales order đầu tiên | 200 |
| 2D.4 | **Con Đường Tơ Lụa** | Setup delivery route, hoàn thành 5 đơn giao hàng | 250 |
| 2D.5 | **Cân Bằng Nguyên Tố** | Tồn kho khớp 100% sau kiểm kê | 300 |

#### 🎱 Nhánh Giải Trí (Entertainment Path)
| Quest | Tên | Hành động thực tế | XP |
|-------|-----|-------------------|-----|
| 2E.1 | **Bày Binh Bố Trận** | Setup 5+ bàn/phòng | 150 |
| 2E.2 | **Khai Trương** | 10 session check-in/check-out hoàn chỉnh | 200 |
| 2E.3 | **Đầu Bếp Tài Ba** | Tạo menu 15+ món | 150 |
| 2E.4 | **Đêm Không Ngủ** | Doanh thu 1 ngày đạt target | 300 |

#### 🏭 Nhánh Sản Xuất (Manufacturing Path)
| Quest | Tên | Hành động thực tế | XP |
|-------|-----|-------------------|-----|
| 2M.1 | **Bản Thiết Kế** | Tạo 3 BOM hoàn chỉnh | 200 |
| 2M.2 | **Chuỗi Cung Ứng** | Setup 5 suppliers, tạo PO đầu tiên | 200 |
| 2M.3 | **Dây Chuyền Vàng** | Hoàn thành 10 production orders | 300 |

**🏰 Boss Challenge Act II:** *"Tháng Vận Hành"*  
→ 30 ngày: Không có đơn hàng trễ, không có task quá hạn  
→ **+1,000 XP, Title "Bậc Thầy Vận Hành"**

---

### Act III — "Tài Chính" (Financial Mastery)
*Unlock: Hoàn thành Act II*

| Quest | Tên | Hành động thực tế | XP |
|-------|-----|-------------------|-----|
| 3.1 | **Sổ Sách Minh Bạch** | 100% đơn hàng có invoice, 0 công nợ quá hạn | 300 |
| 3.2 | **Dòng Tiền Vàng** | Thu đủ 95%+ công nợ trong tháng | 400 |
| 3.3 | **Nhà Phân Tích** | Xem báo cáo P&L 3 tháng liên tiếp | 200 |
| 3.4 | **Tăng Trưởng** | Doanh thu tháng này > tháng trước 10%+ | 500 |
| 3.5 | **Tiết Kiệm Gia** | Giảm chi phí vận hành 5% so với tháng trước | 500 |

**🏰 Boss Challenge Act III:** *"Quý Vàng"*  
→ 3 tháng liên tiếp có lãi  
→ **+2,000 XP, Title "Phù Thủy Tài Chính"**

---

### Act IV — "Đế Chế" (Empire Building)
*Unlock: Level 30+*

| Quest | Tên | Hành động thực tế | XP |
|-------|-----|-------------------|-----|
| 4.1 | **Mở Rộng Lãnh Thổ** | Mở branch thứ 2 | 500 |
| 4.2 | **Đa Ngành** | Vận hành 2 business types khác nhau | 800 |
| 4.3 | **Quân Đoàn** | 50+ nhân viên active | 600 |
| 4.4 | **Tự Động Hóa** | Setup AI Assistant, dùng 30 ngày liên tiếp | 400 |
| 4.5 | **Đế Vương** | 5 branch, 100+ nhân viên, lãi 6 tháng liên tiếp | 2,000 |

---

## 3. Nhiệm Vụ Hàng Ngày (Daily Quests)

*Reset mỗi ngày lúc 00:00, tối đa 5 daily quests*

| Quest | Điều kiện | XP | Streak Bonus |
|-------|-----------|-----|--------------|
| **Điểm Danh Hoàn Hảo** | 100% nhân viên check-in | 20 | x1.5 sau 7 ngày |
| **Không Ai Bỏ Lại** | 0 task quá hạn trong ngày | 20 | x1.5 sau 7 ngày |
| **Nhà Buôn Cần Mẫn** | Tạo ≥3 đơn hàng | 25 | x2 sau 14 ngày |
| **Thu Tiền Đúng Hạn** | Thu ≥1 khoản công nợ | 15 | x1.5 sau 7 ngày |
| **CEO Có Tâm** | Mở app và xem dashboard | 10 | x2 sau 30 ngày |

**Daily Combo:** Hoàn thành cả 5 → Bonus **+50 XP** + random reward

---

## 4. Nhiệm Vụ Tuần (Weekly Challenges)

| Quest | Điều kiện | XP |
|-------|-----------|-----|
| **Tuần Lễ Bất Bại** | 0 đơn hàng bị cancel | 100 |
| **Marathon** | 7/7 daily combo | 200 |
| **Mentor** | Approve 10+ tasks của nhân viên | 80 |
| **Thám Tử** | Xem tất cả báo cáo (attendance, finance, sales) | 60 |
| **Giao Tiếp** | Gửi 5+ thông báo cho team | 50 |

---

## 5. Thành Tựu & Huy Hiệu (Achievements & Badges)

### Phân Loại Độ Hiếm
- 🟢 **Common** — Dễ đạt, ai cũng có
- 🔵 **Rare** — Cần nỗ lực vài ngày
- 🟣 **Epic** — Cần kiên trì vài tuần
- 🟡 **Legendary** — Cần kiên trì vài tháng
- 🔴 **Mythic** — Cực hiếm, <1% CEO đạt được

### Huy Hiệu Hiếm

| Badge | Điều kiện | Độ hiếm |
|-------|-----------|---------|
| **Sắt Đá** | 30 ngày daily combo liên tiếp | 🟡 Legendary |
| **Không Ngủ** | Login lúc 5AM-6AM, 7 ngày liên tiếp | 🟣 Epic |
| **Zero Defect** | 0 complaint từ khách hàng trong 30 ngày | 🟣 Epic |
| **Speed Demon** | Hoàn thành đơn hàng trong <2 giờ | 🔵 Rare |
| **Vua Doanh Thu** | Doanh thu tháng top 1 (leaderboard) | 🟡 Legendary |
| **Người Sắt** | 365 ngày không miss daily login | 🔴 Mythic |
| **Đa Nhân Cách** | Vận hành 3+ business types | 🟣 Epic |

### Huy Hiệu Ẩn (Secret Badges)

| Badge | Điều kiện |
|-------|-----------|
| **Cú Đêm** | Tạo đơn hàng lúc 2AM-4AM |
| **Siêu Nhân** | Approve 50 tasks trong 1 ngày |
| **Phượng Hoàng** | Lỗ 2 tháng liên tiếp → lãi tháng thứ 3 |
| **Easter Egg** | Tìm được hidden feature trong app |

---

## 6. Hệ Thống Mùa (Season System)

Mỗi **quý (3 tháng)** là 1 Season với theme riêng:

| Season | Theme | Focus | Season Reward |
|--------|-------|-------|---------------|
| Q1 | **Mùa Xuân Khởi Đầu** | Growth & Expansion | Title "Chinh Phục Mùa Xuân" |
| Q2 | **Mùa Hè Bùng Nổ** | Revenue & Sales | Title "Vua Mùa Hè" |
| Q3 | **Mùa Thu Thu Hoạch** | Efficiency & Cost | Title "Nhà Chiến Lược" |
| Q4 | **Mùa Đông Sinh Tồn** | Survival & Stability | Title "Bất Khuất" |

Mỗi season có **Season Pass** (30 tiers) — CEO kiếm XP từ daily/weekly/main quest để leo tier.

---

## 7. Leaderboard & Social

| Board | Tiêu chí | Reset |
|-------|----------|-------|
| **CEO Siêng Năng** | Daily combo streak dài nhất | Never |
| **Doanh Nhân Xuất Sắc** | XP trong season | Mỗi quý |
| **Speed Runner** | Hoàn thành Act I-III nhanh nhất | Never |
| **Guild War** | Tổng XP của tất cả nhân viên trong company | Mỗi tháng |

---

## 8. Kiến Trúc Kỹ Thuật

### Database Schema (thêm ~10 bảng)

```sql
-- CEO Game Profile
ceo_profiles (
  id, user_id, level, total_xp, current_title, 
  active_badges[], streak_days, season_tier,
  created_at, updated_at
)

-- Quest Definitions (admin-managed)
quest_definitions (
  id, code, name, description, type ENUM('main','daily','weekly','boss','achievement'),
  act, business_type, prerequisites[], 
  conditions JSONB, xp_reward, badge_reward,
  sort_order, is_active
)

-- User Quest Progress
quest_progress (
  id, user_id, quest_id, status ENUM('locked','available','in_progress','completed'),
  progress_data JSONB, started_at, completed_at
)

-- Daily Quest Tracking
daily_quest_log (
  id, user_id, date, quest_ids[], completion_status JSONB,
  combo_completed BOOLEAN, streak_count INT
)

-- Achievements / Badges
achievements (
  id, code, name, description, icon_url,
  rarity ENUM('common','rare','epic','legendary','mythic'),
  condition_type, condition_value JSONB, is_secret BOOLEAN
)

-- User Unlocked Achievements
user_achievements (
  id, user_id, achievement_id, unlocked_at, notified BOOLEAN
)

-- Season Definitions
seasons (
  id, name, theme, start_date, end_date,
  tier_count INT, rewards_per_tier JSONB
)

-- User Season Progress
season_progress (
  id, user_id, season_id, current_tier, xp_earned,
  rewards_claimed[]
)

-- XP Transaction Log (audit trail)
xp_transactions (
  id, user_id, amount, source_type, source_id,
  description, created_at
)

-- Leaderboard (materialized view, refreshed periodically)
leaderboards (
  type, period, user_id, rank, score, updated_at
)
```

### Quest Condition Engine (JSON-based)

```json
{
  "type": "count",
  "table": "sales_orders",
  "filter": {"status": "completed"},
  "operator": ">=",
  "value": 5,
  "period": "day"
}
```

```json
{
  "type": "streak",
  "condition": {
    "type": "count",
    "table": "attendance_records",
    "filter": {"status": "present"},
    "operator": "=",
    "value": "employee_count"
  },
  "days": 7
}
```

```json
{
  "type": "comparison",
  "metric": "monthly_revenue",
  "compare": "previous_month",
  "operator": ">",
  "percentage": 10
}
```

---

## 9. Open Source & Tham Khảo

### 9.1 Tham Khảo Hệ Thống (Inspiration)

#### Habitica — "Cuộc sống là RPG"
- **Repo:** https://github.com/HabitRPG/habitica (13,700+ stars)
- **Stack:** Vue.js + Node.js + MongoDB
- **Học được gì:**
  - Hệ thống HP/XP/Gold đơn giản nhưng gây nghiện
  - 3 loại task: Habits (lặp lại), Dailies (hàng ngày), To-Dos (1 lần) → map tốt vào quest types
  - Equipment system — CEO có thể "trang bị" tools/badges
  - Guild/Party system — nhiều CEO cùng chơi
  - Streak tracking tạo FOMO mạnh
- **Áp dụng:** Borrow ý tưởng Daily/Habit/To-Do → Daily Quest / Weekly Quest / Main Quest. Streak mechanics gần như copy được nguyên xi

#### Aviquest — "Task Manager RPG"
- **Repo:** https://github.com/whilekofman/aviquest
- **Stack:** MERN (MongoDB, Express, React, Node)
- **Học được gì:**
  - Gacha reward system — random phần thưởng tạo excitement
  - Equipment + Inventory UI
  - Task difficulty levels ảnh hưởng XP
- **Áp dụng:** Gacha system cho Daily Combo reward (random badge/title/cosmetic)

#### Corporations — Business Simulator Game
- **Repo:** https://github.com/IGGAMEMAKER/Corporations (4,790 commits)
- **Học được gì:**
  - Business simulation mechanics: hiring, R&D, market competition
  - Economic systems, investment, expansion
- **Áp dụng:** Tham khảo progression curve cho Act IV (Empire Building)

---

### 9.2 Backend Engines — Có Thể Tận Dụng Trực Tiếp

#### gamification-engine (gengine) ⭐ Khuyến nghị tham khảo
- **Repo:** https://github.com/ActiDoo/gamification-engine (460+ stars, MIT)
- **Stack:** Python + PostgreSQL + REST API + Docker
- **Features:**
  - Multi-level achievements với goals & progress
  - Leaderboard: daily, weekly, monthly, yearly
  - Social-awareness (score among friends)
  - Geo-awareness (score by city)
  - Rules viết bằng Python, dùng variables
  - Custom properties & rewards
  - Multi-language
  - Dependencies giữa achievements (prerequisites & postconditions)
  - Triggers: push notifications khi đạt goal
  - Admin UI sẵn có
  - Docker-ready
- **Đánh giá:** Engine mạnh nhất tìm được. Dùng PostgreSQL — cùng stack với Supabase. Có thể:
  - **(A) Fork & adapt** — chạy song song với Supabase, gọi qua REST
  - **(B) Port logic** — lấy ý tưởng schema + rule engine, viết lại bằng Supabase RPCs/Edge Functions
  - Recommendation: **(B)** — port logic vào Supabase để giữ single database, dùng PostgreSQL functions + triggers

#### Level-Up (Laravel) ⭐ Tham khảo thiết kế
- **Repo:** https://github.com/cjmellor/level-up (656 stars, MIT)
- **Stack:** PHP/Laravel
- **Features:**
  - XP system: addPoints, deductPoints, setPoints
  - Level structure: custom level thresholds
  - Level cap (max level 100)
  - **Multipliers** — điểm nhân đôi/ba theo conditions (ví dụ: tháng 12 x2 XP)
  - Achievements: progress-based (0-100%), secret achievements
  - Streaks: record, break, reset, freeze, archive history
  - Leaderboard service
  - Audit trail cho mọi XP transaction
  - Event-driven (emit events khi level up, achievement unlock, streak break)
- **Đánh giá:** Thiết kế API cực clean. Đặc biệt hay:
  - **Multiplier system** — áp dụng cho SABOHUB: x2 XP vào "Giờ Vàng", x1.5 XP khi hoàn thành tasks trước deadline
  - **Streak freeze** — CEO có thể "freeze" streak khi nghỉ phép, không bị mất combo
  - **Achievement progress** — quest không chỉ pass/fail mà có % tiến độ

#### json-rules-engine ⭐ Khuyến nghị dùng
- **Package:** https://www.npmjs.com/package/json-rules-engine (326K+ weekly downloads)
- **Stack:** JavaScript (Node + Browser)
- **Features:**
  - Rules = JSON, dễ lưu database
  - Boolean operators: ALL, ANY, NOT — nested recursive
  - Custom operators & facts
  - Không dùng eval() — an toàn
  - 17kb gzipped
- **Đánh giá:** Dùng trong Supabase Edge Functions để evaluate quest conditions:
  ```json
  {
    "conditions": {
      "all": [
        { "fact": "orders_completed_today", "operator": "greaterThanInclusive", "value": 3 },
        { "fact": "attendance_rate", "operator": "equal", "value": 100 }
      ]
    },
    "event": { "type": "quest_complete", "params": { "quest_id": "daily_trader", "xp": 25 } }
  }
  ```

---

### 9.3 Flutter Packages — Dùng Trực Tiếp Trong SABOHUB

#### teqani_rewards ⭐ Khuyến nghị thử
- **Package:** https://pub.dev/packages/teqani_rewards (MIT)
- **Features:**
  - Achievement system với pre-built widgets (Cube, Prism, Pyramid, Modern, Gradient cards)
  - Streak tracking với nhiều style (Floating, Circular, Calendar, Pulsating)
  - Challenge system với progress (Circular, Timeline, Flip, Pulse, Wave)
  - Multiple storage: SharedPreferences, SQLite, Hive, Firebase
  - AES-256 encryption
  - Dark/Light mode
  - Localization support
- **Đánh giá:** Package mới (0.1.0) nhưng feature set rất phù hợp. UI widgets đẹp, có thể:
  - Dùng widgets trực tiếp cho achievement cards, streak display
  - Hoặc lấy inspiration cho custom widgets
  - Lưu ý: storage backend cần switch sang Supabase (custom adapter)

#### Confetti & Celebration Effects
| Package | Stars | Mô tả |
|---------|-------|--------|
| `confetti` | Popular | Blast confetti, customizable velocity/gravity/colors |
| `flutter_confetti` | 119+ | Multiple shapes (star, circle, emoji), live demo |
| `easy_conffeti` | New | Achievement, levelUp, celebration presets. Fountain, explosion, fireworks, tornado effects |

**Recommendation:** Dùng `confetti` hoặc `easy_conffeti` cho:
- Level up animation
- Achievement unlock celebration
- Quest completion effect
- Daily combo completion confetti blast

---

### 9.4 Supabase-Native Approach — Recommended Architecture

Thay vì dùng external service, build quest engine trực tiếp trên Supabase:

#### PostgreSQL Triggers
```sql
-- Auto-check quests khi có event xảy ra
CREATE OR REPLACE FUNCTION check_quest_completion()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  -- Khi sales_order completed → check related quests
  PERFORM evaluate_quests(NEW.company_id, 'sales_order_completed');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_order_completed
AFTER UPDATE ON sales_orders
FOR EACH ROW
WHEN (OLD.status != 'completed' AND NEW.status = 'completed')
EXECUTE FUNCTION check_quest_completion();
```

#### Supabase Edge Functions
```typescript
// Quest evaluation engine chạy trên Deno
Deno.serve(async (req) => {
  const { user_id, event_type } = await req.json()
  
  // Load active quests for user
  const quests = await supabase
    .from('quest_progress')
    .select('*, quest:quest_definitions(*)')
    .eq('user_id', user_id)
    .eq('status', 'in_progress')
  
  // Evaluate each quest's conditions
  for (const quest of quests.data) {
    const completed = await evaluateConditions(quest.quest.conditions, user_id)
    if (completed) {
      await completeQuest(user_id, quest.id, quest.quest.xp_reward)
    }
  }
})
```

#### Realtime Leaderboard (Materialized View)
```sql
CREATE MATERIALIZED VIEW leaderboard_monthly AS
SELECT 
  cp.user_id,
  e.full_name,
  c.name as company_name,
  cp.level,
  cp.total_xp,
  RANK() OVER (ORDER BY cp.total_xp DESC) as rank
FROM ceo_profiles cp
JOIN employees e ON cp.user_id = e.id
JOIN companies c ON e.company_id = c.id
WHERE cp.updated_at >= date_trunc('month', now());

-- Refresh mỗi 15 phút
SELECT cron.schedule('refresh-leaderboard', '*/15 * * * *', 
  'REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_monthly');
```

#### Supabase Realtime cho live updates
```dart
// Flutter client subscribe to quest updates
supabase
  .from('quest_progress')
  .stream(primaryKey: ['id'])
  .eq('user_id', currentUserId)
  .listen((data) {
    // Update quest UI in realtime
    ref.read(questProgressProvider.notifier).update(data);
  });
```

---

### 9.5 Tổng Kết — Chiến Lược Tận Dụng

| Thành phần | Chiến lược | Nguồn |
|------------|-----------|-------|
| **Quest Engine** | Build on Supabase (PostgreSQL functions + Edge Functions) | Tham khảo gengine schema |
| **XP/Level System** | Custom Dart + Supabase RPCs | Port logic từ Level-Up |
| **Multipliers** | Custom (x2 giờ vàng, x1.5 early completion) | Level-Up concept |
| **Streak System** | Custom + Supabase | Level-Up freeze/archive pattern |
| **Rule Evaluation** | json-rules-engine trong Edge Functions | npm package |
| **Achievement UI** | teqani_rewards widgets hoặc custom | Flutter package |
| **Celebration FX** | confetti / easy_conffeti | Flutter packages |
| **Leaderboard** | PostgreSQL materialized views + Realtime | Supabase native |
| **Season Pass** | Custom tables + cron refresh | Self-built |
| **Game Design** | Habitica daily/streak + Tycoon progression | Habitica + business sim |

---

## 10. Tham Khảo Từ Games Quản Lý Kinh Doanh

### 10.1 Bản Đồ Game Tham Khảo

| Game | Thể loại | Mechanic hay nhất | Áp dụng cho SABOHUB |
|------|----------|-------------------|---------------------|
| **Supermarket Simulator** | Retail sim | Inventory → Expansion unlock loop | Act II Distribution quests |
| **Shop Titans** | Shop RPG | 3 trụ cột (Craft/Quest/Sell) + Talent Tree | CEO Skill Tree system |
| **Restaurant Tycoon 3** | F&B sim | Employee types + Worker leveling | Staff gamification |
| **Kairosoft (Mega Mall Story)** | Pixel business | Hearts currency + Rank unlock + Research | Hearts = "Uy Tín" currency |
| **Two Point Hospital** | Management sim | Star rating per location (1-3 sao) | Branch Star Rating |
| **Plate Up!** | Co-op restaurant | XP from runs, permanent unlocks | Season rewards |
| **Idle Business Tycoon** | Idle/Tycoon | Prestige rebirth + Upgrade tree | Prestige system per branch |
| **Battle Pass (industry)** | Monetization | Free/Premium track, tier milestones | Season Pass design |

---

### 10.2 Mechanics Đáng "Ăn Cắp" Nhất

#### A. "3 Trụ Cột" — Từ Shop Titans

Shop Titans xây game quanh 3 trụ cột liên kết: **Crafting → Questing → Selling**. Mỗi trụ feed vào trụ kia.

**Áp dụng SABOHUB — 3 Trụ Cột CEO:**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   VẬN HÀNH  │────▶│  KINH DOANH │────▶│   TÀI CHÍNH │
│  (Operate)  │◀────│   (Sell)    │◀────│  (Finance)  │
└─────────────┘     └─────────────┘     └─────────────┘
  Attendance          Orders              Revenue
  Tasks               Customers           Profit/Loss
  HR/Training         Delivery            Cash flow
  Inventory           Marketing           Cost control
```

- **Vận Hành tốt** → có hàng để bán, nhân viên giỏi → **Kinh Doanh tốt**
- **Kinh Doanh tốt** → có doanh thu → **Tài Chính tốt**
- **Tài Chính tốt** → có tiền đầu tư HR, mở rộng → **Vận Hành tốt hơn**

Mỗi trụ có quest riêng + XP riêng. CEO phải balance cả 3 — thiên lệch 1 trụ = bottleneck.

---

#### B. "Star Rating Per Branch" — Từ Two Point Hospital

Two Point Hospital chấm sao mỗi bệnh viện (1-3 sao) dựa trên nhiều tiêu chí. CEO phải đạt đủ điều kiện mới lên sao.

**Áp dụng SABOHUB — Branch Star Rating:**

| Sao | Điều kiện (ví dụ cho Distribution) | Unlock |
|-----|-------------------------------------|--------|
| ⭐ (1 sao) | ≥5 nhân viên, ≥1 warehouse, ≥50 đơn hàng/tháng | Basic reports |
| ⭐⭐ (2 sao) | ≥10 NV, attendance >90%, doanh thu >50M/tháng, 0 đơn trễ | Advanced analytics |
| ⭐⭐⭐ (3 sao) | ≥20 NV, attendance >95%, doanh thu >200M, lãi 3 tháng liên tiếp, NPS >8 | AI Assistant unlock, premium features |

- Tổng sao của tất cả branch = **Company Rating** (hiển thị trên leaderboard)
- CEO có thể compare branch nào yếu nhất → focus cải thiện
- Sao có thể **bị tụt** nếu performance giảm (giống Two Point Hospital)

---

#### C. "Talent Tree / CEO Skill Tree" — Từ Shop Titans

Shop Titans unlock Talent Tree ở level 42, 3 nhánh: Bartering, Crafting, Questing. Mỗi nhánh có passive bonuses.

**Áp dụng SABOHUB — CEO Skill Tree:**

```
                    ┌──────────────┐
                    │   CEO TREE   │
                    │  (Level 20+) │
                    └──────┬───────┘
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  LEADER  │ │ MERCHANT │ │ STRATEGIST│
        │  (Con Người)│ │ (Kinh Doanh)│ │ (Tài Chính)│
        └──────────┘ └──────────┘ └──────────┘
```

**Nhánh Leader (Con Người):**
- Lv1: +10% attendance rate bonus cho team
- Lv2: Unlock "Motivate" — boost task completion speed 1 ngày
- Lv3: Auto-approve tasks dưới mức "easy"
- Lv4: +1 department slot
- Lv5: "Inspiration" — x1.5 XP cho toàn team 24h

**Nhánh Merchant (Kinh Doanh):**
- Lv1: +5% order processing speed
- Lv2: Unlock customer tier auto-upgrade
- Lv3: Discount campaign tool (AI-suggested pricing)
- Lv4: +1 delivery route slot
- Lv5: "Golden Touch" — x2 XP từ sales quests 24h

**Nhánh Strategist (Tài Chính):**
- Lv1: Unlock P&L comparison tool
- Lv2: Auto debt reminder notifications
- Lv3: Cash flow forecast (AI prediction)
- Lv4: Cost optimization suggestions
- Lv5: "Eagle Eye" — See competitors on leaderboard (nếu có)

CEO kiếm **Skill Points** mỗi 5 level. Phải chọn đầu tư vào nhánh nào — tạo diversity giữa các CEO.

---

#### D. "Prestige / Rebirth System" — Từ Idle Tycoon Games

Khi CEO đạt milestone lớn, có thể "Prestige" một branch để:
- Reset branch về level 1
- Nhận permanent multiplier (+0.5x XP cho branch đó mãi mãi)
- Unlock cosmetic title/badge hiếm
- Branch được badge "Prestige I", "Prestige II"...

**Ví dụ:** Branch Quận 7 đạt 3 sao, vận hành 6 tháng liên tục → CEO có thể Prestige:
- Branch giữ nguyên data kinh doanh (không reset data thật!)
- Chỉ reset **game progress** (quest progress, star rating)
- CEO phải đạt lại 3 sao với điều kiện **khó hơn** (+20% threshold)
- Đổi lại: permanent x1.5 XP multiplier cho branch đó

Mechanic này giữ CEO engaged lâu dài — luôn có mục tiêu mới.

---

#### E. "Customer Satisfaction Loop" — Từ Supermarket Simulator

Supermarket Simulator: Giữ hàng đầy kệ → khách hài lòng → nhiều khách hơn → nhiều tiền → mở rộng → cần nhiều hàng hơn → loop tiếp.

**Áp dụng SABOHUB — Business Health Score:**

```
Business Health = weighted average of:
  ├── 📦 Stock Health (30%) — tỉ lệ sản phẩm có hàng / tổng SKU
  ├── 😊 Customer Satisfaction (25%) — tỉ lệ đơn hoàn thành đúng hạn
  ├── 👥 Team Health (25%) — attendance rate + task completion rate  
  └── 💰 Financial Health (20%) — cash flow positive + debt ratio
```

- Business Health Score = 0-100 điểm, hiển thị như "thanh máu" (HP bar) của doanh nghiệp
- Score < 30 → cảnh báo đỏ "Doanh nghiệp đang nguy hiểm!"
- Score > 80 → buff x1.5 XP (doanh nghiệp khỏe = CEO chơi hiệu quả hơn)
- Score = 100 → special achievement "Perfect Health"

---

#### F. "Employee Leveling" — Từ Restaurant Tycoon 3

Restaurant Tycoon 3: Mỗi nhân viên có level, upgrade cải thiện skill cụ thể.

**Áp dụng SABOHUB — Staff cũng có "game profile":**

| Staff Level | Tiêu chí | Badge |
|-------------|----------|-------|
| Tân Binh | Mới vào, <1 tháng | 🟢 Recruit |
| Chiến Sĩ | >90% attendance 3 tháng, >80% task done | 🔵 Warrior |
| Tinh Anh | >95% attendance 6 tháng, >90% task done, 0 complaints | 🟣 Elite |
| Trụ Cột | >1 năm, mentor cho 3+ người mới | 🟡 Pillar |
| Huyền Thoại | >2 năm, top performer 6 tháng liên tiếp | 🔴 Legend |

- Staff level ảnh hưởng Business Health Score
- Nhiều staff level cao → CEO được bonus XP (team mạnh = CEO giỏi quản lý)
- Tạo động lực CEO đầu tư vào nhân sự, không chỉ focus kinh doanh

---

#### G. "Daily Login Calendar" — Từ Mobile Games

Hệ thống phần thưởng login hàng ngày theo calendar:

```
Ngày 1: 10 XP          Ngày 8:  20 XP
Ngày 2: 15 XP          Ngày 9:  25 XP  
Ngày 3: 15 XP          Ngày 10: 30 XP
Ngày 4: 20 XP          ...
Ngày 5: 25 XP          Ngày 28: 100 XP
Ngày 6: 30 XP          Ngày 29: 150 XP
Ngày 7: 50 XP + Badge  Ngày 30: 300 XP + Rare Badge + Title
```

- Miss 1 ngày: restart từ ngày 1 (strict mode) HOẶC tiếp tục nhưng mất bonus (lenient mode)
- CEO có thể dùng "Streak Freeze" (1 lần/tháng) để bảo vệ streak

---

#### H. "Season Pass / Battle Pass" — Từ Industry Standard

```
Season Pass "Mùa Xuân 2026" (90 ngày)

FREE TRACK:                          PREMIUM TRACK (nếu có):
Tier 1:  50 XP                       Tier 1:  100 XP + Exclusive Frame
Tier 5:  Badge "Newcomer"            Tier 5:  Badge "Spring Warrior" (gold)
Tier 10: Title "Chiến Binh Mùa Xuân" Tier 10: Exclusive Avatar Border
Tier 15: 200 XP                      Tier 15: AI Report unlock (1 tháng)
Tier 20: Badge "Nỗ Lực"             Tier 20: Custom theme color
Tier 25: Title upgrade               Tier 25: Badge "Spring Champion" (animated)
Tier 30: Legendary Badge              Tier 30: Mythic Badge + Exclusive Title
```

- Tier lên bằng Season XP (earned từ daily/weekly/main quests)
- Premium track = thêm phần thưởng cosmetic (KHÔNG phải pay-to-win)
- Tất cả rewards là cosmetic: badges, titles, frames, themes — KHÔNG có gameplay advantage

---

#### I. "Research / Unlock System" — Từ Kairosoft

Kairosoft: Dùng "Hearts" (customer happiness currency) để research new features.

**Áp dụng SABOHUB — "Uy Tín" Currency:**

CEO kiếm "Uy Tín" (Reputation Points) từ:
- Customer satisfaction cao → +Uy Tín
- 0 đơn trễ trong tuần → +Uy Tín
- Staff satisfaction cao → +Uy Tín
- Community contribution (giúp CEO khác trên leaderboard) → +Uy Tín

Dùng Uy Tín để unlock:
- Advanced reports (P&L drill-down, trend analysis)
- AI features (demand prediction, auto-reorder suggestion)
- Custom dashboard layouts
- Premium widgets (real-time GPS tracker, etc.)

Mechanic này: **Vận hành tốt → unlock tools tốt hơn → vận hành tốt hơn nữa** (virtuous cycle)

---

### 10.3 So Sánh: Game Gốc vs. SABOHUB Adaptation

| Mechanic gốc | Game | SABOHUB Version | Khác biệt |
|---------------|------|-----------------|-----------|
| Stock shelves → sell → expand | Supermarket Sim | Inventory → Orders → Branch expand | Data thật, không simulate |
| 3 pillars (Craft/Quest/Sell) | Shop Titans | 3 pillars (Operate/Sell/Finance) | Mỗi pillar có quest tree riêng |
| Star rating per hospital | Two Point Hospital | Star rating per branch | Sao có thể tụt |
| Talent Tree at Lv42 | Shop Titans | CEO Skill Tree at Lv20 | 3 nhánh: Leader/Merchant/Strategist |
| Worker leveling (Chef Lv1-5) | Restaurant Tycoon 3 | Staff auto-leveling by performance | Dựa trên data thật, không manual |
| Prestige rebirth | Idle Tycoon | Branch Prestige (harder requirements) | Chỉ reset game progress, giữ data thật |
| Hearts → Research | Kairosoft | Uy Tín → Unlock features | Earned from real business metrics |
| Battle Pass tiers | Industry | Season Pass (free + premium) | Cosmetic only, no pay-to-win |
| HP/damage system | Habitica | Business Health Score (0-100) | Calculated from real KPIs |
| Daily login calendar | Mobile games | Daily login + Daily quests combo | XP scales with streak length |

---

### 10.4 Anti-Patterns — Những Thứ KHÔNG Nên Copy

| Anti-pattern | Game ví dụ | Tại sao không dùng |
|--------------|-----------|-------------------|
| **Energy gates** (chờ X giờ để chơi tiếp) | Shop Titans | CEO cần app lúc nào cũng dùng được, không chặn |
| **Pay-to-win** (trả tiền để mạnh hơn) | Nhiều mobile games | Phá hủy fairness, leaderboard vô nghĩa |
| **Loss aversion quá mạnh** (mất hết nếu miss 1 ngày) | Strict streak games | CEO bận, cần lenient — dùng Streak Freeze thay vì punish |
| **Grind vô nghĩa** (lặp lại task không giá trị) | Nhiều RPG | Mỗi quest phải map vào hành động kinh doanh có giá trị thật |
| **RNG quá nhiều** (random ảnh hưởng gameplay) | Gacha games | Quest completion dựa trên effort, không phải may rủi |
| **FOMO toxic** (nếu không chơi 24/7 sẽ thua) | Competitive mobile | CEO có cuộc sống, design cho 15-30 phút engagement/ngày |

---

## 11. Roadmap Triển Khai (Updated)

### Phase 1 — Foundation + Core Loop (3 tuần) ✅ COMPLETED 2026-03-02
- [x] Database schema: 8 tables (ceo_profiles, quest_definitions, quest_progress, daily_quest_log, achievements, user_achievements, xp_transactions, branch_star_ratings) ✅
- [x] PostgreSQL functions: xp_for_level, level_from_xp, title_for_level, add_xp, record_daily_login, get_ceo_leaderboard ✅
- [x] RLS policies for all tables ✅
- [x] Dart models: CeoProfile, QuestDefinition, QuestProgress, Achievement, XpTransaction, DailyQuestLog ✅
- [x] GamificationService with full CRUD + quest auto-unlock ✅
- [x] Riverpod providers: ceoProfileProvider, activeQuestsProvider, leaderboardProvider, etc. ✅
- [x] UI widgets: XpProgressBar, LevelBadge, QuestCard, StreakCounter, BusinessHealthBar, AchievementCard, CeoGameSummaryCard ✅
- [x] Screens: QuestHubPage (4 tabs), CeoGameProfilePage (full profile with skill tree) ✅
- [x] GoRouter routes + CEO navigation sidebar integration ✅
- [x] CeoGameSummaryCard embedded on CEO Dashboard ✅
- [x] Seed data: 15 quest definitions (Act I + Act II sample), 14 achievements ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 2 — Daily Loop + Engagement (2 tuần) ✅
- [x] Quest Auto-Evaluation Engine: PostgreSQL functions (`evaluate_user_quests`, `evaluate_daily_quests`) checking real business data (employees, attendance, tasks, sales_orders, payments) ✅
- [x] DB Triggers on key tables (employees, branches, tasks, attendance, sales_orders, customers, deliveries, warehouses, products, tables, table_sessions, payments) ✅
- [x] Daily quests (5 quests: attendance, tasks, orders, payment, login) + Daily Combo (+50 XP bonus) ✅
- [x] Weekly challenges (5 seeded: Bất Bại, Marathon, Mentor, Thám Tử, Giao Tiếp) ✅
- [x] Streak Freeze system: `use_streak_freeze()` RPC + StreakFreezeButton UI ✅
- [x] Confetti celebration overlay (`QuestCelebrationOverlay`) with confetti package ✅
- [x] In-app notification bar (`QuestNotificationBar`) for quest/XP/level-up/combo events ✅
- [x] DailyQuestPanel widget with auto-evaluation, combo tracker, weekly calendar ✅
- [x] Quest Hub page updated: daily tab with auto-refresh, main quests with evaluate-on-pull ✅
- [x] Service + Provider updates: `evaluateDailyQuests`, `evaluateMainQuests`, `useStreakFreeze`, `DailyQuestResult`, `CelebrationNotifier` ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 3 — Achievements + Staff Gamification (2 tuần) ✅
- [x] Achievement Auto-Evaluation Engine: `evaluate_achievements()` RPC with 12 condition evaluators ✅
- [x] Condition helpers: `_ach_quest_complete`, `_ach_streak`, `_ach_order_speed`, `_ach_early_login`, `_ach_zero_complaints`, `_ach_business_types`, `_ach_leaderboard_rank`, `_ach_action_time`, `_ach_daily_action_count`, `_ach_financial_recovery`, `_ach_staff_level`, `_ach_employee_count` ✅
- [x] Secret badges: Night Owl, Superman, Phoenix, Perfectionist, Comeback ✅
- [x] Achievement unlock celebration: confetti overlay + notification on auto-scan ✅
- [x] Achievement scan button on Achievements tab with progress summary header ✅
- [x] Staff gamification: `employee_game_profiles` table (level, XP, scores, streaks, badges) ✅
- [x] Staff auto-leveling: Recruit → Sắt → Đồng → Bạc → Vàng → Bạch Kim → Kim Cương → Huyền Thoại ✅
- [x] `calculate_employee_scores()` RPC: auto-score attendance (35%), tasks (35%), punctuality (30%) ✅
- [x] Employee attendance streak trigger (`update_employee_streak`) ✅
- [x] Business Health Score: `calculate_business_health()` RPC (attendance 30%, tasks 30%, overdue 20%, activity 20%) ✅
- [x] `StaffLeaderboard` widget + `StaffPerformanceCard` widget ✅
- [x] `StaffPerformancePage` (full-screen, with summary header, recalculate button, detail cards) ✅
- [x] `get_staff_leaderboard()` RPC + providers (`staffProfilesProvider`, `staffLeaderboardProvider`) ✅
- [x] Quest Hub 5th tab "Team" with compact staff leaderboard ✅
- [x] Route: `/staff-performance` registered in GoRouter ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 4 — Depth Systems (3 tuần) ✅
- [x] `skill_definitions` table: 15 skills (5 per branch: Leader, Merchant, Strategist) with passive bonuses ✅
- [x] `allocate_skill_point()` RPC: tier-gated allocation, prerequisite checks, auto skill-point grant every 5 levels from Lv.20 ✅
- [x] `get_skill_effects()` RPC: returns active bonuses (XP bonus, reputation bonus, combo bonus, golden hour extend, etc.) ✅
- [x] Interactive `SkillTreeWidget`: visual skill nodes with unlock dialog, locked/next/allocated states ✅
- [x] XP Multiplier: `xp_multiplier_events` table + `get_current_multiplier()` RPC ✅
- [x] Golden Hour (7-9AM x1.5, 8-10PM x1.5), Weekend Warrior (x1.3), First Blood (x2) ✅
- [x] Streak-based multiplier (+0.05x per 7 days, max +0.5x) + Skill Tree global bonus ✅
- [x] `add_xp_with_multiplier()`: auto-applies current multiplier to XP gains ✅
- [x] `XpMultiplierBadge` widget: shows active multiplier on profile page ✅
- [x] Uy Tín Store: `uytin_store_items` + `uytin_purchases` tables ✅
- [x] 10 store items: Extra Freeze, Double Daily, VIP Badge, XP Boosts, Dark Theme, Custom Title, Analytics Pro, AI Assistant ✅
- [x] `purchase_store_item()` RPC: cost check, level gate, one-time purchase guard, effect application ✅
- [x] `UytinStorePage`: full store UI with balance header, active purchases, category sections, buy dialog ✅
- [x] Act III quests (5): Mở Chi Nhánh, Đạo Quân, Bậc Thầy Tài Chính, Đa Năng, BOSS: Đại Ca ✅
- [x] Act IV quests (5): Đế Chế, Tông Sư, Nhà Đầu Tư, Huyền Thoại, FINAL BOSS: Huyền Thoại CEO ✅
- [x] Act II distribution extended (3): Vận Chuyển 50, Khách VIP, BOSS: Ông Chủ Phân Phối ✅
- [x] Act II entertainment extended (2): Phục Vụ Hoàn Hảo, BOSS: Ông Chủ Giải Trí ✅
- [x] CEO Game Profile upgraded: XP Multiplier badge, Quick Actions (Store, Team), interactive Skill Tree ✅
- [x] Route `/uytin-store` registered in GoRouter ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 5 — Social & Seasons (3 tuần) ✅
- [x] **Materialized View Leaderboards**: `mv_ceo_leaderboard` (all-time), `mv_ceo_monthly` (this month XP), `mv_company_ranking` (Guild War) ✅
- [x] `refresh_leaderboards()` function: concurrent refresh of all 3 materialized views ✅
- [x] RPC wrappers: `get_global_leaderboard()`, `get_monthly_leaderboard()`, `get_company_ranking()` ✅
- [x] `LeaderboardPage`: tabbed (Global + Monthly), refresh button, medals for top 3, compact rank tiles ✅
- [x] **Season System**: `seasons` table, `season_pass_tiers` table (10 tiers), `season_progress` table ✅
- [x] Season 1 "Mùa Khởi Nghiệp" seeded (Mar–May 2026, x1.1 bonus) with 10 free-track rewards ✅
- [x] `add_season_xp()` trigger: auto-credits Season XP on every `xp_transactions` INSERT ✅
- [x] `claim_season_tier()` RPC: validate XP, prevent double-claim, apply reward (XP/reputation/badge/title/streak_freeze/skill_point) ✅
- [x] `get_season_pass()` RPC: returns current season info, user progress, days remaining ✅
- [x] `SeasonPassPage`: gradient header, progress bar, tier list with claim buttons ✅
- [x] **Prestige/Rebirth**: `prestige_history` table + `prestige_level`/`prestige_bonuses` columns on `ceo_profiles` ✅
- [x] `prestige_reset()` RPC: requires Level 50, resets level/XP/skills, grants permanent bonuses (+5% XP, +3% rep, +1 freeze, badge/title) ✅
- [x] `get_prestige_info()` RPC: current bonuses, can_prestige flag, highest level ever ✅
- [x] `PrestigeCard` widget: visual card with star display, bonus breakdown, prestige button with confirmation dialog ✅
- [x] **Company Ranking (Guild War)**: `CompanyRankingPage` with podium (top 3), rank cards with stats (employees, health, staff rating) ✅
- [x] Dart models: `SeasonPassInfo`, `SeasonPassTier`, `PrestigeInfo`, `CompanyRankEntry` ✅
- [x] Service methods: 10 new methods for leaderboards, seasons, prestige ✅
- [x] Providers: `globalLeaderboardProvider`, `monthlyLeaderboardProvider`, `companyRankingProvider`, `seasonPassProvider`, `seasonTiersProvider`, `prestigeInfoProvider` ✅
- [x] Actions: `claimSeasonTier()`, `doPrestige()`, `refreshLeaderboards()` with celebration integration ✅
- [x] Routes: `/season-pass`, `/company-ranking`, `/leaderboard` registered in GoRouter ✅
- [x] CEO Game Profile upgraded: Social actions row (Leaderboard, Season Pass, Guild War) + Prestige Card ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 6 — Analytics, Premium Pass & Notifications ✅
- [x] **Analytics SQL Functions** (6 RPCs): `get_quest_analytics()`, `get_xp_analytics()`, `get_engagement_metrics()`, `get_quest_dropoff()`, `get_level_distribution()`, `get_xp_trend()` ✅
- [x] `get_engagement_metrics()`: 15 KPIs — DAU/WAU/MAU rates, avg streak, avg level, XP today, quests completed, health, prestige, season participants ✅
- [x] `get_quest_dropoff()`: abandoned quest analysis (>14 days inactive) with dropoff rate ✅
- [x] `get_level_distribution()`: player count per tier (Tân Binh → Huyền Thoại) ✅
- [x] `get_xp_trend()`: daily XP/transactions/unique users for last 14 days ✅
- [x] `generate_weekly_summary()`: XP earned, quests completed, achievements, streak, top source ✅
- [x] **Analytics Dashboard**: `GamificationAnalyticsPage` with weekly summary, engagement grid, XP trend chart, XP breakdown, level distribution, quest drop-off ✅
- [x] **Premium Season Pass**: `premium_pass_purchases` table, `buy_premium_pass()` RPC (200 Uy Tín), `has_premium_pass()` check ✅
- [x] 10 premium-tier cosmetic rewards (VIP Badge, Golden Frame, Elite Badge, Legendary Frame, exclusive titles) ✅
- [x] Season Pass page updated: premium banner with buy button, premium flag integration ✅
- [x] **Notification System**: `game_notifications` table, 10 notification types ✅
- [x] `generate_game_notifications()`: auto-generates streak_warning, prestige_ready, season_ending, achievement_near ✅
- [x] `get_game_notifications()`, `mark_notifications_read()`, `get_unread_notification_count()` RPCs ✅
- [x] `GameNotificationBell` widget: unread count badge on bell icon ✅
- [x] `GameNotificationsPage`: full notification list with icons, read/unread state, age formatting ✅
- [x] Dart models: `GameNotification`, `WeeklySummary`, `EngagementMetric`, `XpAnalytics`, `QuestDropoff`, `LevelDistribution`, `XpTrendPoint` ✅
- [x] Service: 12 new methods (analytics, notifications, premium pass) ✅
- [x] Providers: 9 new providers + 2 new actions (markNotificationsRead, buyPremiumPass) ✅
- [x] Routes: `/gamification-analytics`, `/game-notifications` ✅
- [x] Quest Hub updated: notification bell + analytics button in app bar ✅
- [x] Migration applied to Supabase production ✅
- [x] Flutter web build passing ✅

### Phase 7 — Adaptive Business Config + AI Quest Generator ✅

**Architecture: 3-Tier Config System**

Thay vì hardcode quest cho từng business type, hệ thống sử dụng config-driven architecture:

**Tier 1: Business Type Config** (`business_type_config` table)
- Maps abstract concepts → concrete database tables per business type
- 8 business types pre-configured: distribution, billiards, restaurant, cafe, hotel, retail, manufacturing, corporation
- 7 concepts per type: primary_transaction, revenue_event, inventory_object, customer_object, workspace_object, peak_hours, daily_transaction_target
- Total: 57 config rows seeded

**Tier 2: Quest Templates** (`quest_templates` table)
- Abstract quest patterns that resolve dynamically via config
- Name/description use `{display_name}`, `{threshold}` placeholders
- Threshold curves: `{"beginner": 1, "intermediate": 3, "advanced": 5}`
- 13 templates: 5 daily, 3 weekly, 5 main quest patterns
- `resolve_quest_template()` function resolves template → concrete quest

**Tier 3: AI Quest Generator** (Supabase Edge Function + Gemini 2.0 Flash)
- Edge Function `generate-quest-config` calls Gemini API
- Auto-generates `business_type_config` entries for ANY new business type
- Auto-generates custom quests tailored to specific business
- CEO review flow: pending → approved/rejected → applied
- `ai_generated_configs` table stores generated configs with audit trail
- `apply_ai_config()` RPC applies approved configs to production tables

**Database Changes:**
- [x] `business_type_config` table: (business_type, concept) → (table_name, filter, display_name, icon, metadata) ✅
- [x] `quest_templates` table: abstract quest patterns with concept mapping ✅
- [x] `ai_generated_configs` table: AI-generated configs pending CEO approval ✅
- [x] `evaluate_daily_quests()` refactored: reads config dynamically via `format()` + `EXECUTE` ✅
- [x] `resolve_quest_template()`: resolves template → concrete quest for any business type ✅
- [x] `get_business_config()`: RPC for Flutter to fetch config ✅
- [x] `initialize_quests_for_company()`: business-type-aware quest initialization ✅
- [x] `apply_ai_config()`: applies AI-generated configs after CEO approval ✅
- [x] 57 config rows seeded for 8 business types ✅
- [x] 13 quest templates seeded ✅

**Edge Function:**
- [x] `generate-quest-config/index.ts`: Gemini 2.0 Flash integration ✅
- [x] System prompt with Vietnamese RPG quest generation rules ✅
- [x] Company context injection (name, type, employee count, revenue) ✅
- [x] Reference existing configs for consistent style ✅
- [x] JSON response parsing with fallback regex extraction ✅

**Flutter Changes:**
- [x] `BusinessTypeMapping`, `BusinessConfig`, `AiGeneratedConfig` models ✅
- [x] Service: `getBusinessConfig()`, `initializeQuestsForCompany()`, `generateAiConfig()`, `applyAiConfig()`, `getCompanyBusinessType()`, `rejectAiConfig()` ✅
- [x] Providers: `businessConfigProvider`, `aiConfigProvider` ✅
- [x] `AiQuestConfigPage`: current config view + AI generate + preview + approve/reject flow ✅
- [x] Route: `/ai-quest-config` ✅
- [x] Quest Hub: AI Config button (auto_awesome icon) in app bar ✅
- [x] Migration applied to Supabase production ✅
- [x] Zero linter errors ✅

### Phase 8 — Future Iteration (ongoing)
- [ ] A/B test engagement metrics
- [ ] New quest lines mỗi season
- [ ] Real-time push notifications (Supabase Realtime + FCM)
- [ ] Balance XP based on analytics insights
- [ ] Seasonal events & limited-time quests
- [ ] AI auto-balance: use analytics data to auto-adjust XP/thresholds
- [ ] Multi-language quest names via AI translation
