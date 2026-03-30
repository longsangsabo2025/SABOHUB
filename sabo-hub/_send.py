import requests
response = requests.post(
    "https://api.resend.com/emails",
    headers={
        "Authorization": "Bearer re_AqAaLdb8_5yarkY2QxJsjKG1eJhwKofWw",
        "Content-Type": "application/json"
    },
    json={
        "from": "SABOHUB <noreply@sabo.com.vn>",
        "to": ["longsangsabo@gmail.com"],
        "subject": "[SABOHUB] Test Email - 04/03/2026",
        "html": "<h1>SABOHUB</h1><p>Xin chao CEO! Day la email test.</p><p style='color:green'>He thong email da hoat dong!</p>"
    }
)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
