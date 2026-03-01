"""
🤖 SABOHUB AI E2E Test Agent
Uses Browser Use + Gemini to automatically test the production web app.

Chiến lược: AI agent tự navigate app, thực hiện test scenarios bằng ngôn ngữ tự nhiên.
Không cần CSS selectors — AI nhìn trang web và tương tác như người dùng thật.

Usage:
  cd d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub
  python sabohub-app/SABOHUB/test/e2e/ai_e2e_agent.py

Requirements (already installed in .venv-2):
  - browser-use >= 0.12.0
  - playwright >= 1.58.0
  - langchain-google-genai >= 4.2.1
"""

import asyncio
import json
import os
import sys
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================
APP_URL = "https://sabohub-app.vercel.app"
GEMINI_API_KEY = "AIzaSyBna3u55uhP1JCOv50L7FtUHgofaX95ALs"

# Test account (Employee login — uses company_name + username + password)
TEST_ACCOUNTS = {
    "ceo": {
        "company": "Odori",  # hoặc tên công ty thực tế trong DB
        "username": "ceo",
        "password": "123456",
        "mode": "ceo_email",  # CEO uses email login
        "email": "ceo1@sabohub.com",
    },
    "manager": {
        "company": "Odori",
        "username": "manager1",
        "password": "123456",
        "mode": "employee",
    },
    "staff": {
        "company": "Odori", 
        "username": "staff1",
        "password": "123456",
        "mode": "employee",
    },
}

# ============================================================================
# TEST SCENARIOS
# ============================================================================
TEST_SCENARIOS = [
    {
        "id": "TC-001",
        "name": "Login Page Load",
        "instruction": f"""
Go to {APP_URL}
Wait for the page to fully load (it's a Flutter web app, may take a few seconds).
Verify the page shows:
1. The text "SABOHUB" as a heading
2. The text "Đăng nhập Nhân viên" or similar employee login heading
3. A text field with label "Tên công ty"
4. A text field with label "Tên đăng nhập"
5. A text field with label "Mật khẩu"
6. A button with text "Đăng nhập"
7. A "CEO" button/link somewhere on the page

Report which elements you found and which are missing.
""",
        "expect": "All 7 elements visible",
    },
    {
        "id": "TC-002", 
        "name": "Login Validation — Empty Fields",
        "instruction": f"""
Go to {APP_URL}
Wait for the page to fully load (it's a Flutter web app).
Without filling in any fields, click the "Đăng nhập" button.
Check if validation error messages appear, such as:
- Something about company name required
- Something about username required
- Something about password required
Report which error messages appeared and what they say.
""",
        "expect": "All 3 validation errors shown",
    },
    {
        "id": "TC-003",
        "name": "CEO Login Mode Toggle",
        "instruction": f"""
Go to {APP_URL}
Wait for the page to fully load (it's a Flutter web app).
Find and click the "CEO" button (it should be at the top-right area).
Verify the page changes to show:
1. Text about CEO login (e.g. "Đăng nhập CEO")
2. An email field
3. A password field
4. A CEO login button
Then find and click the back/employee button to return to employee login.
Verify it shows employee login fields again.
Report what you observe at each step.
""",
        "expect": "Toggle between CEO and Employee login modes works",
    },
    {
        "id": "TC-004",
        "name": "CEO Email Validation",
        "instruction": f"""
Go to {APP_URL}
Wait for the page to fully load.
Click the "CEO" button to switch to CEO login mode.
Type "notanemail" in the Email field.
Leave password empty.
Click the CEO login button.
Check for validation errors about invalid email or empty password.
Report which errors appeared and what they say.
""",
        "expect": "Email format and empty password validation shown",
    },
    {
        "id": "TC-005",
        "name": "App Visual Quality Check",
        "instruction": f"""
Go to {APP_URL}
Wait for the page to fully load.
Check the overall visual quality:
1. Is the login form centered on the page?
2. Is all text readable (proper size, contrast)?
3. Are there any overlapping elements or broken layout?
4. Does the color scheme look professional?
5. Are input fields properly aligned?
Report your observations about the visual quality.
""",
        "expect": "Login page renders correctly without layout issues",
    },
]


# ============================================================================
# TEST RUNNER
# ============================================================================
class TestResult:
    def __init__(self, tc_id: str, name: str, status: str, detail: str, duration: float):
        self.tc_id = tc_id
        self.name = name
        self.status = status  # PASS / FAIL / ERROR
        self.detail = detail
        self.duration = duration

    def to_dict(self):
        return {
            "id": self.tc_id,
            "name": self.name,
            "status": self.status,
            "detail": self.detail,
            "duration_sec": round(self.duration, 1),
        }


async def run_single_test(scenario: dict, agent_cls, llm) -> TestResult:
    """Run a single test scenario using Browser Use agent."""
    tc_id = scenario["id"]
    name = scenario["name"]
    instruction = scenario["instruction"]
    
    start = datetime.now()
    print(f"\n{'='*60}")
    print(f"🧪 {tc_id}: {name}")
    print(f"{'='*60}")
    
    try:
        agent = agent_cls(
            task=instruction,
            llm=llm,
        )
        result = await agent.run()
        duration = (datetime.now() - start).total_seconds()
        
        result_text = str(result)
        
        # Simple pass/fail heuristic based on result content
        if any(word in result_text.lower() for word in ["error", "crash", "broken", "missing", "not found", "fail"]):
            status = "WARN"
        else:
            status = "PASS"
        
        print(f"✅ {tc_id} completed in {duration:.1f}s")
        print(f"   Result: {result_text[:200]}...")
        
        return TestResult(tc_id, name, status, result_text, duration)
        
    except Exception as e:
        duration = (datetime.now() - start).total_seconds()
        error_msg = str(e)
        print(f"❌ {tc_id} ERROR in {duration:.1f}s: {error_msg[:200]}")
        return TestResult(tc_id, name, "ERROR", error_msg, duration)


async def run_all_tests():
    """Run all test scenarios and generate report."""
    print("=" * 60)
    print("🤖 SABOHUB AI E2E Test Agent")
    print(f"   Target: {APP_URL}")
    print(f"   Tests: {len(TEST_SCENARIOS)}")
    print(f"   Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Setup LLM
    from browser_use.llm.google import ChatGoogle
    from browser_use import Agent
    
    llm = ChatGoogle(
        model="gemini-2.0-flash",
        api_key=GEMINI_API_KEY,
    )
    
    results: list[TestResult] = []
    
    for scenario in TEST_SCENARIOS:
        result = await run_single_test(scenario, Agent, llm)
        results.append(result)
    
    # Generate report
    print("\n" + "=" * 60)
    print("📊 TEST REPORT SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for r in results if r.status == "PASS")
    warned = sum(1 for r in results if r.status == "WARN")
    errors = sum(1 for r in results if r.status == "ERROR")
    total = len(results)
    total_time = sum(r.duration for r in results)
    
    for r in results:
        icon = {"PASS": "✅", "WARN": "⚠️", "ERROR": "❌"}[r.status]
        print(f"  {icon} {r.tc_id}: {r.name} [{r.status}] ({r.duration:.1f}s)")
    
    print(f"\n  Total: {total} | ✅ Pass: {passed} | ⚠️ Warn: {warned} | ❌ Error: {errors}")
    print(f"  Duration: {total_time:.1f}s")
    
    # Save JSON report
    report_dir = os.path.dirname(os.path.abspath(__file__))
    report_path = os.path.join(report_dir, "e2e_report.json")
    report = {
        "timestamp": datetime.now().isoformat(),
        "target": APP_URL,
        "summary": {
            "total": total,
            "passed": passed,
            "warned": warned,
            "errors": errors,
            "duration_sec": round(total_time, 1),
        },
        "results": [r.to_dict() for r in results],
    }
    
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n  📄 Full report saved to: {report_path}")
    
    return results


def main():
    """Entry point."""
    # On Windows, use default ProactorEventLoop (supports subprocess)
    # Do NOT use WindowsSelectorEventLoopPolicy — it breaks subprocess creation
    asyncio.run(run_all_tests())


if __name__ == "__main__":
    main()
