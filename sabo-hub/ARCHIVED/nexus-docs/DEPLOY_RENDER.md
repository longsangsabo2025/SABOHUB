# 🚀 Hướng dẫn Deploy "Neural Link" lên Render

Đây là hướng dẫn "Elon Musk Style" - Nhanh, Gọn, Hiệu quả.

## 1. Chuẩn bị
Đảm bảo bạn đã có tài khoản [Render.com](https://render.com) và đã đẩy code mới nhất lên GitHub.

## 2. Deploy (1 Cú Click)

1.  Truy cập Dashboard Render.
2.  Chọn **New +** -> **Blueprints**.
3.  Kết nối với Repository GitHub của bạn (`sabohub-nexus`).
4.  Render sẽ tự động phát hiện file `render.yaml`.
5.  Nhấn **Apply**.

## 3. Cấu hình Biến Môi Trường (Quan trọng)
Trong quá trình setup (hoặc sau khi tạo xong), vào phần **Environment** của service `sabo-neural-link` và điền các giá trị từ file `.env` của bạn:

- `TELEGRAM_BOT_TOKEN`: (Token của Bot Father)
- `VITE_SUPABASE_URL`: (URL Supabase)
- `VITE_SUPABASE_ANON_KEY`: (Key Anon)
- `VITE_SUPABASE_POOLER_URL`: (Connection String của Supabase - **Lưu ý: Dùng Port 5432 Session Mode nếu có thể, hoặc Pooler 6543**)

## 4. Lưu ý về gói Free Tier
- Gói Free của Render sẽ "ngủ" (spin down) sau 15 phút không hoạt động.
- Vì Bot của chúng ta có tích hợp sẵn "Health Check Server" (Port 3000), bạn có thể dùng các dịch vụ uptime miễn phí (như UptimeRobot) để ping vào URL của Render (ví dụ: `https://sabo-neural-link.onrender.com`) mỗi 5 phút.
- **Kết quả:** Bot sẽ thức 24/7 hoàn toàn miễn phí.

---
*SABO Ecosystem - Powered by Neural Link V2*
