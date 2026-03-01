"""
🎯 SABOHUB Quick Smoke Test — Single scenario runner
Chạy nhanh 1 scenario để verify Browser Use + Gemini hoạt động.

Usage:
  cd d:/0.PROJECTS/02-SABO-ECOSYSTEM/sabo-hub
  .venv-2/Scripts/activate
  python sabohub-app/SABOHUB/test/e2e/smoke_test.py
"""

import asyncio
import os
import sys

APP_URL = "https://sabohub-app.vercel.app"
GEMINI_API_KEY = "AIzaSyBna3u55uhP1JCOv50L7FtUHgofaX95ALs"


async def smoke_test():
    """Quick smoke test: just verify login page loads."""
    from browser_use import Agent
    from browser_use.llm.google import ChatGoogle
    
    llm = ChatGoogle(
        model="gemini-2.0-flash",
        api_key=GEMINI_API_KEY,
    )
    
    task = f"""
Go to {APP_URL}

Wait a few seconds for the page to fully load (it's a Flutter web app).

Look at the page and tell me:
1. What is the main heading text?
2. What input fields do you see? List their labels.
3. What buttons do you see?
4. Is there a CEO login option?

Just describe what you see on the page. Be specific about Vietnamese text.
"""
    
    print("🚀 Starting smoke test...")
    print(f"   Target: {APP_URL}/login")
    print(f"   LLM: gemini-2.0-flash")
    print()
    
    agent = Agent(
        task=task,
        llm=llm,
    )
    
    result = await agent.run()
    
    print("\n" + "=" * 60)
    print("📋 SMOKE TEST RESULT:")
    print("=" * 60)
    print(result)
    print("=" * 60)


def main():
    # On Windows, use default ProactorEventLoop (supports subprocess)
    # Do NOT use WindowsSelectorEventLoopPolicy — it breaks subprocess creation
    asyncio.run(smoke_test())


if __name__ == "__main__":
    main()
