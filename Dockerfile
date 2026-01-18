# Flutter Android Build Dockerfile
FROM cirrusci/flutter:stable

# Встановити робочу директорію
WORKDIR /app

# Налаштувати Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin

# Встановити необхідні Android SDK компоненти
RUN yes | sdkmanager --licenses 2>/dev/null || true
RUN sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" "ndk;25.1.8937393" || echo "SDK вже встановлено"

# Перевірити Flutter
RUN flutter doctor -v

# Копіювати файли проекту (спочатку pubspec для кешування)
COPY pubspec.yaml pubspec.lock* ./

# Встановити залежності
RUN flutter pub get

# Копіювати решту файлів
COPY lib/ ./lib/
COPY android/ ./android/
COPY firebase.json .firebaserc firestore.rules firestore.indexes.json* ./
COPY analysis_options.yaml ./

# Створити директорію assets (якщо потрібно)
RUN mkdir -p ./assets

# Очистити та зібрати APK
RUN flutter clean && \
    flutter pub get && \
    flutter build apk --release

# Показати інформацію про зібраний APK
RUN ls -lh build/app/outputs/flutter-apk/app-release.apk || echo "APK не знайдено"

# При запуску: скопіювати APK в /output
CMD ["sh", "-c", "mkdir -p /output && cp -v /app/build/app/outputs/flutter-apk/app-release.apk /output/app-release.apk 2>/dev/null || (echo 'Помилка: APK не знайдено' && exit 1) && echo '✅ APK готовий!' && ls -lh /output/app-release.apk"]
