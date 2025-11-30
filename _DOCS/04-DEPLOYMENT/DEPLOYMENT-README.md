# 🚀 Quick Start - Deployment Guide

Xem file chi tiết tại: [CODEMAGIC-SETUP-GUIDE.md](./CODEMAGIC-SETUP-GUIDE.md)

## ⚡ Quick Commands

### Pre-deployment Check
```powershell
# Windows
.\scripts\pre-deploy-check.ps1

# Mac/Linux
bash scripts/pre-deploy-check.sh
```

### Generate Android Keystore
```powershell
# Windows
.\scripts\generate-keystore.ps1

# Mac/Linux
bash scripts/generate-keystore.sh
```

### Build Commands
```bash
# iOS
flutter build ipa --release

# Android
flutter build appbundle --release

# Run tests
flutter test

# Analyze code
flutter analyze
```

## 📱 App Information

- **App Name**: SABOHUB - Quản lý quán bida
- **Bundle ID (iOS)**: com.sabohub.app
- **Package Name (Android)**: com.sabohub.app
- **Version**: 1.0.0+1

## 🔑 Required Accounts

1. **CodeMagic**: https://codemagic.io
2. **Apple Developer**: https://developer.apple.com
3. **Google Play Console**: https://play.google.com/console

## 📋 Deployment Checklists

- [x] ✅ codemagic.yaml configured
- [x] ✅ iOS project setup
- [x] ✅ Android project setup
- [x] ✅ Environment variables template
- [x] ✅ Deployment scripts
- [x] ✅ Documentation complete

## 📚 Documentation Files

- **CODEMAGIC-SETUP-GUIDE.md** - Complete setup guide
- **DEPLOYMENT-CHECKLIST.md** - Pre-deployment checklist
- **codemagic.yaml** - CI/CD configuration
- **android/key.properties.example** - Android signing template

## 🆘 Need Help?

Xem chi tiết trong [CODEMAGIC-SETUP-GUIDE.md](./CODEMAGIC-SETUP-GUIDE.md) hoặc:
- CodeMagic Docs: https://docs.codemagic.io/
- Flutter Deployment: https://docs.flutter.dev/deployment

---

**Ready to deploy! 🎉**
