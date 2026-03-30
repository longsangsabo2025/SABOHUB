import requests

API_KEY = 're_AqAaLdb8_5yarkY2QxJsjKG1eJhwKofWw'
TO_EMAIL = 'longsangsabo@gmail.com'

emails = [
    {
        'subject': '[SABOHUB] Task moi: Kiem tra bao cao tai chinh Q1',
        'html': '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 32px; border-radius: 12px 12px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">Task moi duoc giao</h1>
    </div>
    <div style="background: #ffffff; padding: 32px; border: 1px solid #e5e7eb; border-top: none;">
        <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 0 8px 8px 0; margin-bottom: 24px;">
            <span style="font-weight: 600; color: #92400e;">Uu tien: CAO</span>
        </div>
        <h2 style="color: #1f2937; margin: 0 0 16px 0;">Kiem tra bao cao tai chinh Q1</h2>
        <div style="background: #f9fafb; padding: 20px; border-radius: 8px; margin-bottom: 24px;">
            <table style="width: 100%; border-collapse: collapse;">
                <tr><td style="padding: 8px 0; color: #6b7280;">Nguoi giao:</td><td style="padding: 8px 0; font-weight: 500;">Vo Ngoc Diem</td></tr>
                <tr><td style="padding: 8px 0; color: #6b7280;">Du an:</td><td style="padding: 8px 0; font-weight: 500;">Bao cao Tai chinh 2026</td></tr>
                <tr><td style="padding: 8px 0; color: #6b7280;">Deadline:</td><td style="padding: 8px 0; font-weight: 500; color: #dc2626;">10/03/2026</td></tr>
            </table>
        </div>
        <p style="color: #374151; line-height: 1.6;">Can kiem tra va phe duyet bao cao tai chinh quy 1 nam 2026.</p>
        <a href="https://sabohub.vercel.app" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-top: 16px;">Xem Task</a>
    </div>
    <div style="background: #f3f4f6; padding: 20px 32px; border-radius: 0 0 12px 12px; text-align: center;">
        <p style="color: #6b7280; margin: 0; font-size: 14px;">SABOHUB - He thong quan ly doanh nghiep</p>
    </div>
</div>'''
    },
    {
        'subject': '[SABOHUB] Bao cao hang ngay - 04/03/2026',
        'html': '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 32px; border-radius: 12px 12px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">Bao cao hang ngay</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0;">04/03/2026</p>
    </div>
    <div style="background: #ffffff; padding: 32px; border: 1px solid #e5e7eb; border-top: none;">
        <table style="width: 100%; margin-bottom: 24px;">
            <tr>
                <td style="width: 33%; background: #f0fdf4; padding: 20px; border-radius: 12px; text-align: center;">
                    <div style="font-size: 32px; font-weight: 700; color: #16a34a;">5</div>
                    <div style="color: #166534; font-size: 14px;">Hoan thanh</div>
                </td>
                <td style="width: 33%; background: #fef9c3; padding: 20px; border-radius: 12px; text-align: center;">
                    <div style="font-size: 32px; font-weight: 700; color: #ca8a04;">3</div>
                    <div style="color: #854d0e; font-size: 14px;">Dang lam</div>
                </td>
                <td style="width: 33%; background: #fee2e2; padding: 20px; border-radius: 12px; text-align: center;">
                    <div style="font-size: 32px; font-weight: 700; color: #dc2626;">2</div>
                    <div style="color: #991b1b; font-size: 14px;">Qua han</div>
                </td>
            </tr>
        </table>
        <h3 style="color: #1f2937; margin-bottom: 16px;">Tasks can chu y:</h3>
        <ul style="padding-left: 20px; color: #374151;">
            <li style="margin-bottom: 8px;">Phe duyet ke hoach marketing (Qua han 2 ngay)</li>
            <li style="margin-bottom: 8px;">Kiem tra don hang #DH2026-0301 (Deadline hom nay)</li>
            <li>Hop voi nha cung cap ABC (Deadline ngay mai)</li>
        </ul>
        <a href="https://sabohub.vercel.app" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-top: 16px;">Vao Dashboard</a>
    </div>
    <div style="background: #f3f4f6; padding: 20px 32px; border-radius: 0 0 12px 12px; text-align: center;">
        <p style="color: #6b7280; margin: 0; font-size: 14px;">SABOHUB - He thong quan ly doanh nghiep</p>
    </div>
</div>'''
    },
    {
        'subject': '[SABOHUB] Can phe duyet: Ke hoach nhan su Q2',
        'html': '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
    <div style="background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%); padding: 32px; border-radius: 12px 12px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">Yeu cau phe duyet</h1>
    </div>
    <div style="background: #ffffff; padding: 32px; border: 1px solid #e5e7eb; border-top: none;">
        <div style="background: #fef3c7; border-radius: 8px; padding: 16px; margin-bottom: 24px; text-align: center;">
            <span style="font-size: 14px; color: #92400e;">Can phe duyet truoc: <strong>07/03/2026</strong></span>
        </div>
        <h2 style="color: #1f2937; margin: 0 0 16px 0;">Ke hoach nhan su Q2</h2>
        <div style="background: #f9fafb; padding: 20px; border-radius: 8px; margin-bottom: 24px;">
            <table style="width: 100%; border-collapse: collapse;">
                <tr><td style="padding: 8px 0; color: #6b7280;">Nguoi gui:</td><td style="padding: 8px 0; font-weight: 500;">Nguyen Van A (HR Manager)</td></tr>
                <tr><td style="padding: 8px 0; color: #6b7280;">Du an:</td><td style="padding: 8px 0; font-weight: 500;">Ke hoach nhan su 2026</td></tr>
            </table>
        </div>
        <p style="color: #374151; line-height: 1.6;">De xuat tuyen dung 5 nhan vien moi cho phong Kinh doanh va 2 nhan vien cho phong CNTT trong Q2/2026.</p>
        <table style="width: 100%; margin-top: 24px;">
            <tr>
                <td style="width: 50%; padding-right: 6px;"><a href="https://sabohub.vercel.app" style="display: block; background: #16a34a; color: white; padding: 14px 20px; border-radius: 8px; text-decoration: none; font-weight: 600; text-align: center;">PHE DUYET</a></td>
                <td style="width: 50%; padding-left: 6px;"><a href="https://sabohub.vercel.app" style="display: block; background: #dc2626; color: white; padding: 14px 20px; border-radius: 8px; text-decoration: none; font-weight: 600; text-align: center;">TU CHOI</a></td>
            </tr>
        </table>
    </div>
    <div style="background: #f3f4f6; padding: 20px 32px; border-radius: 0 0 12px 12px; text-align: center;">
        <p style="color: #6b7280; margin: 0; font-size: 14px;">SABOHUB - He thong quan ly doanh nghiep</p>
    </div>
</div>'''
    }
]

print('Dang gui emails den longsangsabo@gmail.com...')
print('='*50)

for i, email in enumerate(emails, 1):
    response = requests.post(
        'https://api.resend.com/emails',
        headers={
            'Authorization': f'Bearer {API_KEY}',
            'Content-Type': 'application/json'
        },
        json={
            'from': 'SABOHUB <noreply@resend.dev>',
            'to': [TO_EMAIL],
            'subject': email['subject'],
            'html': email['html']
        }
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f'{i}. OK - {email["subject"]}')
        print(f'   ID: {result.get("id", "N/A")}')
    else:
        print(f'{i}. LOI - Status {response.status_code}')
        print(f'   {response.text}')
    print()

print('='*50)
print('Hoan thanh! Kiem tra hop thu longsangsabo@gmail.com')
