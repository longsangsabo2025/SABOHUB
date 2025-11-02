# 🚀 SABOHUB - Deployment Checklist

## 📋 Pre-Deployment Checklist

### ✅ Code Quality
- [ ] All tests passing (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] No TODO or FIXME in production code
- [ ] All console.log/print statements removed or disabled

### ✅ App Configuration
- [ ] App name updated: "SABOHUB"
- [ ] Bundle ID: `com.sabohub.app`
- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] Environment variables configured (.env)

### ✅ Assets & Resources
- [ ] App icons prepared (iOS & Android)
  - iOS: All sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  - Android: All densities in `android/app/src/main/res/`
- [ ] Launch screen/Splash screen configured
- [ ] All images optimized (compressed)
- [ ] All fonts included and declared

### ✅ Permissions & Security
- [ ] Required permissions declared
  - iOS: `Info.plist` descriptions
  - Android: `AndroidManifest.xml` permissions
- [ ] Sensitive data removed from code
- [ ] API keys secured (environment variables)
- [ ] SSL certificate pinning (if needed)
- [ ] ProGuard/R8 rules configured (Android)

### ✅ Backend & API
- [ ] Production API endpoints configured
- [ ] Supabase project in production mode
- [ ] Database RLS policies active
- [ ] API rate limiting configured
- [ ] Error handling implemented
- [ ] Timeout settings configured

### ✅ Testing
- [ ] Tested on multiple iOS devices/simulators
- [ ] Tested on multiple Android devices/emulators
- [ ] Tested on different screen sizes
- [ ] Tested on different OS versions
- [ ] Network connectivity scenarios tested
- [ ] Offline mode tested (if applicable)
- [ ] Deep linking tested (if applicable)
- [ ] Push notifications tested (if applicable)

### ✅ App Store Assets
- [ ] Screenshots prepared (all required sizes)
  - iOS: 6.7", 6.5", 5.5"
  - Android: Phone, 7", 10"
- [ ] App preview video (optional but recommended)
- [ ] App description written (Vietnamese & English)
- [ ] Keywords researched and selected
- [ ] Privacy policy published (URL)
- [ ] Terms of service prepared (if needed)
- [ ] Support email/website ready

### ✅ Legal & Compliance
- [ ] Privacy policy covers all data collection
- [ ] GDPR compliance (if applicable)
- [ ] Age rating determined
- [ ] Content rating questionnaire completed
- [ ] Copyright notices included
- [ ] Third-party licenses included

---

## 🍎 iOS Specific Checklist

### App Store Connect
- [ ] App created in App Store Connect
- [ ] Bundle ID registered
- [ ] App Store Connect API key generated
- [ ] Certificates & provisioning profiles ready
- [ ] Team ID noted
- [ ] App categories selected

### Info.plist Configuration
- [ ] `CFBundleDisplayName` set to "SABOHUB"
- [ ] `CFBundleIdentifier` = `com.sabohub.app`
- [ ] `ITSAppUsesNonExemptEncryption` set to false
- [ ] Camera/Photos permissions descriptions (if used)
- [ ] Location permissions descriptions (if used)
- [ ] URL schemes configured (if deep linking)

### Build Settings
- [ ] Deployment target set (iOS 12.0+)
- [ ] Architectures: arm64
- [ ] Bitcode disabled (Flutter requirement)
- [ ] Build mode: Release
- [ ] Signing: Automatic or Manual configured

### TestFlight
- [ ] Internal testers added
- [ ] External testers (optional)
- [ ] Test builds uploaded
- [ ] Beta testing completed
- [ ] Feedback collected and addressed

### App Store Submission
- [ ] App information completed
- [ ] Age rating set
- [ ] Content rights confirmed
- [ ] Export compliance information
- [ ] Pricing & availability set
- [ ] Release options selected (manual/automatic)

---

## 🤖 Android Specific Checklist

### Google Play Console
- [ ] App created in Google Play Console
- [ ] Package name: `com.sabohub.app`
- [ ] App categories selected
- [ ] Service account created for API access
- [ ] Keystore file secured (NEVER commit to git)

### AndroidManifest.xml
- [ ] Package name = `com.sabohub.app`
- [ ] Permissions declared with proper descriptions
- [ ] Internet permission added
- [ ] Activities declared
- [ ] Deep link intent filters (if applicable)

### Build Configuration
- [ ] `applicationId` = `com.sabohub.app`
- [ ] `minSdk` = 23 (Android 6.0)
- [ ] `targetSdk` = 36 (Android 14)
- [ ] `compileSdk` = 36
- [ ] Version code incremented
- [ ] Version name updated

### Signing Configuration
- [ ] Release keystore created
- [ ] `key.properties` configured (NOT committed)
- [ ] `build.gradle` signing config added
- [ ] ProGuard rules configured
- [ ] R8 shrinking enabled

### Google Play Store
- [ ] Store listing completed
  - Title, short & full description
  - App icon (512x512)
  - Feature graphic (1024x500)
  - Screenshots (min 2)
- [ ] Content rating completed
- [ ] Target audience selected
- [ ] Privacy policy URL added
- [ ] App access requirements specified

### Internal Testing
- [ ] Internal testing track created
- [ ] Test users added
- [ ] AAB uploaded
- [ ] Testing completed
- [ ] Issues resolved

### Production Release
- [ ] Production release created
- [ ] Release notes written
- [ ] Rollout percentage set (optional)
- [ ] Review submission completed

---

## 🔧 CodeMagic CI/CD Checklist

### Repository Setup
- [ ] Repository connected to CodeMagic
- [ ] `codemagic.yaml` file committed
- [ ] Branch triggers configured
- [ ] Build triggers configured

### Environment Variables
- [ ] `SUPABASE_URL` set
- [ ] `SUPABASE_ANON_KEY` set
- [ ] `BUNDLE_ID` set (iOS)
- [ ] `PACKAGE_NAME` set (Android)
- [ ] Other secrets configured

### iOS Configuration
- [ ] App Store Connect integration added
- [ ] API key uploaded
- [ ] Issuer ID set
- [ ] Key ID set
- [ ] Code signing configured
- [ ] Provisioning profiles set

### Android Configuration
- [ ] Google Play integration added
- [ ] Service account JSON uploaded
- [ ] Keystore uploaded
- [ ] Keystore password set
- [ ] Key alias set
- [ ] Key password set

### Workflows
- [ ] iOS workflow tested
- [ ] Android workflow tested
- [ ] Build scripts validated
- [ ] Test scripts validated
- [ ] Artifact paths correct

### Notifications
- [ ] Email notifications configured
- [ ] Slack/Discord webhooks (optional)
- [ ] Success notifications enabled
- [ ] Failure notifications enabled

---

## 📊 Post-Deployment Checklist

### Monitoring
- [ ] Crash reporting configured (Firebase Crashlytics/Sentry)
- [ ] Analytics configured (Firebase Analytics/Mixpanel)
- [ ] Performance monitoring enabled
- [ ] Error tracking active

### App Stores
- [ ] iOS app live on App Store
- [ ] Android app live on Google Play
- [ ] App links work correctly
- [ ] Search visibility verified

### User Feedback
- [ ] Support email monitored
- [ ] App Store reviews monitored
- [ ] Google Play reviews monitored
- [ ] In-app feedback mechanism working

### Marketing
- [ ] App Store optimization (ASO) completed
- [ ] Keywords optimized
- [ ] Screenshots A/B tested (optional)
- [ ] Social media announcement prepared
- [ ] Website updated with app links

### Documentation
- [ ] User documentation/FAQ created
- [ ] Release notes published
- [ ] Changelog updated
- [ ] Team notified of launch

---

## 🎯 Launch Day Checklist

### Final Checks
- [ ] All features working in production
- [ ] No critical bugs reported
- [ ] Server capacity verified
- [ ] Support team briefed
- [ ] Rollback plan prepared

### Go Live
- [ ] iOS app status: **Pending Developer Release** → **Ready for Sale**
- [ ] Android app: **Release to Production**
- [ ] App links verified
- [ ] First user installations confirmed

### Communication
- [ ] Team notified
- [ ] Stakeholders informed
- [ ] Social media announcement posted
- [ ] Email campaign sent (if applicable)
- [ ] Press release (if applicable)

---

## 📱 Version Tracking

| Version | iOS Build | Android Build | Release Date | Notes |
|---------|-----------|---------------|--------------|-------|
| 1.0.0   | 1         | 1             | YYYY-MM-DD   | Initial release |
| 1.0.1   | 2         | 2             | YYYY-MM-DD   | Bug fixes |
| 1.1.0   | 3         | 3             | YYYY-MM-DD   | New features |

---

## 🆘 Emergency Contacts

- **CodeMagic Support**: support@codemagic.io
- **Apple Developer Support**: https://developer.apple.com/support/
- **Google Play Support**: https://support.google.com/googleplay/
- **Team Lead**: [Your Name/Email]
- **Backend Team**: [Backend Contact]
- **QA Team**: [QA Contact]

---

## ✅ Sign-Off

- [ ] **Developer**: Verified all code changes ____________ (Date/Signature)
- [ ] **QA**: Testing completed ____________ (Date/Signature)
- [ ] **Product Owner**: Release approved ____________ (Date/Signature)
- [ ] **Tech Lead**: Technical review passed ____________ (Date/Signature)

---

**Last Updated**: [Current Date]
**Next Review**: [Next Deployment Date]
