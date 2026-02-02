# Android Release Build Instructions

## Prerequisites

1. Install Android Studio and Android SDK
2. Install Java JDK 17 or later

## Creating Production Keystore

### Step 1: Generate keystore file

```bash
cd android

# Generate new keystore (one-time setup)
keytool -genkey -v -keystore yaok-release.keystore -alias yaok-release -keyalg RSA -keysize 2048 -validity 10000

# Answer the prompts:
# - Enter keystore password: [SAVE THIS SECURELY]
# - Re-enter new password: [same as above]
# - What is your first and last name?: Poruch Studio
# - What is the name of your organizational unit?: Mobile Development
# - What is the name of your organization?: Poruch
# - What is the name of your City or Locality?: [Your City]
# - What is the name of your State or Province?: [Your State]
# - What is the two-letter country code for this unit?: UA
# - Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct?: yes
# - Enter key password for <yaok-release>: [SAVE THIS SECURELY]
```

### Step 2: Create keystore.properties

```bash
cd android
cp keystore.properties.example keystore.properties
```

Edit `android/keystore.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=yaok-release
storeFile=../yaok-release.keystore
```

⚠️ **IMPORTANT**: Never commit `keystore.properties` or `yaok-release.keystore` to git!

### Step 3: Update .gitignore

Add to `android/.gitignore`:
```
keystore.properties
*.keystore
*.jks
```

## Building Release APK

```bash
cd android
./gradlew assembleRelease

# Output will be at:
# app/build/outputs/apk/release/app-release.apk
```

## Building Release AAB (for Play Store)

```bash
cd android
./gradlew bundleRelease

# Output will be at:
# app/build/outputs/bundle/release/app-release.aab
```

## Verifying Signature

```bash
# Check APK signature
jarsigner -verify -verbose -certs app/build/outputs/apk/release/app-release.apk

# View certificate details
keytool -list -v -keystore yaok-release.keystore -alias yaok-release
```

## Security Best Practices

1. **Store keystore file securely**:
   - Keep backup in secure location (encrypted drive, password manager)
   - Never commit to version control
   - Consider using Android App Bundle signing by Google Play

2. **Protect passwords**:
   - Use strong, unique passwords
   - Store in password manager
   - Consider using environment variables in CI/CD

3. **ProGuard/R8**:
   - Already enabled in `build.gradle`
   - Review `proguard-rules.pro` for app-specific rules
   - Test thoroughly after enabling obfuscation

## CI/CD Setup

For automated builds, set environment variables:

```yaml
# GitHub Actions example
env:
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
  KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
  KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }} # base64 encoded
```

Then in build:
```bash
echo $KEYSTORE_FILE | base64 -d > android/yaok-release.keystore
```

## Troubleshooting

### "Failed to read key from keystore"
- Check password in `keystore.properties`
- Verify keystore file path is correct

### "Keystore was tampered with"
- Keystore file is corrupted
- Restore from backup

### Build fails with ProGuard errors
- Check `proguard-rules.pro` for missing rules
- Add `-dontwarn` for third-party library warnings
- Use `-keep` rules for reflection-based code
