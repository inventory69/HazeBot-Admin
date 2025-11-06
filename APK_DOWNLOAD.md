# APK Download - Quick Guide

## 📥 Wo finde ich die APK?

### Option 1: Latest Release (Empfohlen)

**Direkt herunterladen:**
1. Gehe zu: https://github.com/inventory69/HazeBot-Admin/releases/tag/latest
2. Scrolle zu **Assets**
3. Klicke auf `hazebot-admin-test-release.apk`
4. APK wird heruntergeladen

**Vorteile:**
- ✅ Immer die neueste Version
- ✅ Direkte APK-Datei (kein ZIP)
- ✅ Release-Notes mit Commit-Info
- ✅ Wird automatisch bei jedem Push aktualisiert

### Option 2: Workflow Artifacts

1. Gehe zu: https://github.com/inventory69/HazeBot-Admin/actions
2. Klicke auf den neuesten erfolgreichen Workflow
3. Scrolle zu **Artifacts**
4. Download das ZIP
5. Entpacke das ZIP → APK darin

**Nachteile:**
- ❌ Als ZIP verpackt
- ❌ Artifacts laufen nach 30 Tagen ab
- ❌ Erfordert GitHub-Login

---

## 🔄 Wie funktioniert das?

Bei jedem Push auf `main`:
1. GitHub Actions baut automatisch die Test-APK
2. Erstellt/aktualisiert das "latest" Release
3. APK wird als Asset angehängt
4. Release-Notes enthalten Commit-Info

Bei Git Tags (z.B. `v1.0.0`):
1. Erstellt ein versioniertes Release
2. APK wird als Asset angehängt
3. "latest" bleibt für schnelle Downloads

---

## 📱 Installation

1. **APK herunterladen** (siehe oben)
2. **Auf Android-Gerät übertragen**
3. **Installieren**:
   - "Installation aus unbekannten Quellen" erlauben
   - APK öffnen und installieren
4. **App öffnen und einloggen**

---

## 🔐 Login-Daten

**Admin:**
- Username: `inventory69`
- Password: `x8vDJ1FHkkM0s7`

**Test User:**
- Username: `duke`
- Password: `eLourKNqRyh7x4`

---

## ⚙️ Test-Konfiguration

Alle APKs sind für **TEST** konfiguriert:
- API URL: `https://test-hazebot-admin.hzwd.xyz/api`
- Environment: TEST
- Logging: Debug Mode

---

## 🏷️ Release-Tags erstellen

Für versionierte Releases:

```bash
cd /home/liq/gitProjects/HazeBot-Admin
git tag v1.0.0
git push origin v1.0.0
```

Erstellt Release: `v1.0.0` zusätzlich zu "latest"
