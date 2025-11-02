# 🚀 AI Features Quick Start Guide

## ✅ Setup Complete!

OpenAI API Key đã được cấu hình thành công! Tất cả AI features đã sẵn sàng hoạt động.

---

## 📋 Cấu hình đã hoàn tất:

### 1. Environment Variables
- ✅ `.env` - Flutter app configuration
- ✅ `supabase/functions/.env` - Edge Functions configuration
- ✅ `.gitignore` - API keys được bảo vệ, không bị commit

### 2. OpenAI API Key
```
OPENAI_API_KEY=sk-proj-VYTbHFUMA...
```
**Lưu ý:** Key này đã được lưu local và **KHÔNG** bao giờ được commit lên Git!

---

## 🎯 Các tính năng đã kích hoạt:

### 1. 💬 AI Chat
- **Model:** GPT-4 Turbo Preview
- **Tính năng:**
  - Real-time conversation
  - Context-aware responses
  - Vietnamese language support
  - Conversation history
  - Usage tracking

**Cách test:**
1. Chạy app: `flutter run -d chrome`
2. Vào Company Details → AI Assistant tab
3. Gửi tin nhắn: "Xin chào! Phân tích doanh thu của nhà hàng tôi."

---

### 2. 📎 File Upload & AI Analysis

#### Image Analysis với OpenAI Vision
- **Model:** GPT-4 Vision Preview
- **Phân tích:**
  - Vệ sinh & sạch sẽ
  - Ánh sáng & bố cục
  - Điểm cần cải thiện
  - Insights cho nhà hàng

**Cách test:**
1. Click vào 📎 icon trong chat input
2. Upload ảnh nhà hàng/món ăn
3. AI tự động phân tích (10-15 giây)
4. Xem kết quả trong File Gallery (folder icon)

#### Document Processing
- **Supported:** PDF, DOCX, XLSX, TXT
- **Tính năng:**
  - Text extraction
  - Document summarization (ready)
  - Key info extraction (ready)

---

### 3. 💡 AI Recommendations
- **Tính năng:**
  - Auto-generated suggestions
  - Categories: Feature, Process, Growth, Finance, Operations
  - Accept/Reject workflow
  - Implementation tracking

**Cách test:**
1. Click vào 💡 icon trong AI Assistant header
2. Xem danh sách recommendations
3. Click vào để xem chi tiết
4. Accept/Reject recommendations

---

## 🔧 Development Commands

### Start Flutter App
```bash
# Web (Chrome)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Test Edge Functions Locally
```bash
# Start Supabase local development
supabase start

# Test ai-chat function
curl -i --location --request POST 'http://localhost:54321/functions/v1/ai-chat' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"assistant_id":"xxx","company_id":"xxx","message":"Hello"}'

# Test process-file function  
curl -i --location --request POST 'http://localhost:54321/functions/v1/process-file' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"file_id":"xxx"}'
```

### Deploy Edge Functions
```bash
# Deploy ai-chat
supabase functions deploy ai-chat --no-verify-jwt

# Deploy process-file
supabase functions deploy process-file --no-verify-jwt

# Set secrets in Supabase Dashboard
supabase secrets set OPENAI_API_KEY=sk-proj-VYTbHFUMA...
```

---

## 📊 Usage & Cost Tracking

### OpenAI API Costs (Estimated)
| Feature | Model | Cost per 1K tokens |
|---------|-------|-------------------|
| Chat | GPT-4 Turbo | $0.01 prompt / $0.03 completion |
| Vision | GPT-4 Vision | $0.01 prompt / $0.03 completion |
| Embeddings | text-embedding-3-small | $0.00002 |

### Monthly Usage Estimate
- 1,000 chat messages: ~$20-30
- 500 image analyses: ~$15-25
- 200 document summaries: ~$10-15
**Total:** ~$45-70/month

### Monitor Usage
1. Vào Company Details → AI Assistant tab
2. Xem Usage Stats Card (top)
3. Track:
   - Token usage
   - Message count
   - Estimated cost

---

## 🧪 Testing Checklist

### Basic Tests
- [ ] Gửi chat message và nhận response
- [ ] Upload ảnh và xem phân tích
- [ ] Upload PDF/document
- [ ] Xem file gallery
- [ ] Delete file
- [ ] Re-process failed file
- [ ] Xem recommendations list

### Advanced Tests
- [ ] Chat với context (nhiều messages liên tiếp)
- [ ] Upload nhiều files cùng lúc
- [ ] Test error handling (upload file quá lớn)
- [ ] Accept/Reject recommendations
- [ ] View usage analytics
- [ ] Test Vietnamese prompts

---

## 🐛 Troubleshooting

### Issue: "OpenAI API key not configured"
**Solution:** 
1. Check `.env` file có `OPENAI_API_KEY`
2. Restart Flutter app
3. Redeploy Edge Functions với secret

### Issue: "File processing failed"
**Solution:**
1. Check file size < 10MB
2. Check file type supported
3. Click "Xử lý lại" button
4. Check Supabase logs

### Issue: "Unauthorized"
**Solution:**
1. Login lại vào app
2. Check user có quyền access company không
3. Check RLS policies trong Supabase

### Issue: Slow response
**Solution:**
1. Normal: GPT-4 mất 2-5 giây
2. Vision: 10-15 giây cho image analysis
3. Check network connection
4. Check OpenAI API status

---

## 📈 Performance Tips

### Optimize Chat
- Giới hạn conversation history (10-20 messages)
- Use shorter prompts khi có thể
- Cache common responses

### Optimize File Processing
- Compress images trước upload
- Use appropriate file formats
- Batch process when possible

### Optimize Costs
- Monitor usage regularly
- Set budget alerts
- Use GPT-3.5 for simple tasks (optional)
- Implement caching for repeated queries

---

## 🔐 Security Best Practices

### API Keys
- ✅ NEVER commit `.env` to Git
- ✅ Use different keys for dev/staging/production
- ✅ Rotate keys regularly (every 3-6 months)
- ✅ Set usage limits in OpenAI dashboard

### RLS Policies
- ✅ All tables protected với Row Level Security
- ✅ Users chỉ access data của company họ
- ✅ File storage private by default
- ✅ Authentication required cho mọi requests

---

## 📚 Documentation

### Full Documentation
- `AI-ASSISTANT-ROADMAP.md` - Complete roadmap
- `PHASE-3-COMPLETE.md` - File processing details
- `AI-ASSISTANT-100-COMPLETE.md` - Complete summary
- `AI-FEATURES-QUICKSTART.md` - This guide

### API References
- [OpenAI API Docs](https://platform.openai.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)

---

## 🎉 Ready to Use!

Tất cả AI features đã **100% sẵn sàng**! 

### Next Steps:
1. ✅ Chạy app: `flutter run -d chrome`
2. ✅ Test chat với AI
3. ✅ Upload và phân tích files
4. ✅ Xem recommendations
5. ✅ Monitor usage & costs

### Production Deployment:
1. Deploy Edge Functions to Supabase
2. Set OPENAI_API_KEY secret trong Supabase Dashboard
3. Run database migrations
4. Deploy Flutter app
5. Test end-to-end
6. Go live! 🚀

---

**💡 Tip:** Bắt đầu với test trên local development trước khi deploy production!

**🎯 Goal:** Revolutionize restaurant management với AI! 🍽️✨
