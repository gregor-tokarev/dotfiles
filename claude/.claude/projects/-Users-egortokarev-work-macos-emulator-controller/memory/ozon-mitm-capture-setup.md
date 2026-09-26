---
name: ozon-mitm-capture-setup
description: How to capture Ozon Android app HTTPS traffic via the MITM proxy on the emulator
metadata: 
  node_type: memory
  type: project
  originSessionId: ac949056-c529-45b9-b24a-6f8b5b43f8ff
---

Capturing the Ozon app's HTTPS traffic (prices ride on `api.ozon.ru/composer-api.bx/page/json/v2`) requires a **rootable** emulator, not the Play image. Verified working 2026-07-07; mechanism mirrors the sibling repo `../ozonparser-mob` (goproxy MITM + system-store CA, **no Frida, no repackaged APK, no pinning bypass** — Ozon's `network_security_config` trusts `system` CAs and doesn't pin composer-api).

Non-obvious facts:
- The local `ozon` AVD is `google_apis_playstore` (android-35) → **NOT rootable** (`adbd cannot run as root`), so HTTPS MITM is impossible on it. Use `Pixel_3_XL` = `google_apis` (android-33, arm64) which IS rootable. Its system image must be installed: `sdkmanager "system-images;android-33;google_apis;arm64-v8a"`.
- Emulator needs `ANDROID_SDK_ROOT=$HOME/Library/Android/sdk` exported or it fails with "Cannot find AVD system path".
- Boot rootable: `emulator -avd Pixel_3_XL -writable-system -selinux permissive -no-snapshot`.
- Trust CA at system level: `adb root && adb remount`, then `~/.local/bin/adb-install-cert --cert certs/mitm-ca.pem --cert-format pem --mode permanently` (installs to `/system/etc/security/cacerts/<subject_hash_old>.0`; our CA hash is `11b8920e`).
- Install stock app: `adb install -r -d ../ozonparser-mob/ozon.apk`.
- **Launch Ozon via its explicit activity** `am start -n ru.ozon.app.android/.ui.start.AppHostActivity` — `monkey` does NOT reliably start it, and `https://www.ozon.ru/...` deeplinks open Chrome, not the app.
- Point device at proxy: reverse tunnel `adb reverse tcp:8080 tcp:8080` + `settings put global http_proxy 127.0.0.1:8080`. Android only re-reads http_proxy on reconnect, so toggle `cmd connectivity airplane-mode enable`/`disable` after. StartProxy's auto-config now does all of this.
- Fresh/unprovisioned installs get **403 `fab_*` anti-fraud challenges** on composer-api (not a capture bug). Getting 200 price JSON needs a real user session / PVZ+region set, like ozonparser-mob does (it harvests cookies from legit app sessions and publishes to a Redis stream).

See [[ozon-traffic-capture-rpcs]].
