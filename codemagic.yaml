workflows:
  android-release:
    name: Android AAB Build
    max_build_duration: 60
    instance_type: mac_mini_m1
    environment:
      flutter: stable
    scripts:
      - flutter pub get
      - flutter build appbundle --release
    artifacts:
      - build/app/outputs/bundle/release/*.aab
