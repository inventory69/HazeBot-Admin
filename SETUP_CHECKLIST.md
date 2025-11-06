# GitHub Actions Setup - Quick Guide

## ✅ Was wurde gemacht:

### 1. Benutzer-Verwaltung (HazeBot)
- ✅ Benutzer werden jetzt aus `.env` geladen
- ✅ `duke` ist in `.env` als `API_EXTRA_USERS=duke:eLourKNqRyh7x4` gespeichert
- ✅ Unterstützt mehrere Benutzer (komma-getrennt)

### 2. GitHub Actions (HazeBot-Admin)
- ✅ Workflow erstellt: `.github/workflows/build-apk.yml`
- ✅ Baut automatisch **Test-APKs** mit Test-API-URL
- ✅ APK-Namen enthalten "-test" zur Kennzeichnung
- ✅ Dokumentation: `GITHUB_ACTIONS.md`

---

## 📋 Nächste Schritte:

### 1. Push zum GitHub Repository

**HazeBot-Admin (neues Repo):**
```bash
cd /home/liq/gitProjects/HazeBot-Admin

# Erstelle GitHub Repository (auf github.com)
# Dann:
git remote add origin https://github.com/YOURUSERNAME/HazeBot-Admin.git
git push -u origin main
```

### 2. GitHub Secret hinzufügen

1. Gehe zu: `https://github.com/YOURUSERNAME/HazeBot-Admin/settings/secrets/actions`
2. Klicke: **New repository secret**
3. Name: `TEST_API_BASE_URL`
4. Value: `https://test-hazebot-admin.hzwd.xyz/api`
5. Klicke: **Add secret**

### 3. Workflow testen

**Option A - Automatisch:**
Push einen Commit und der Workflow läuft automatisch

**Option B - Manuell:**
1. Gehe zu: Actions Tab
2. Wähle: "Build Android Test APK"
3. Klicke: "Run workflow"
4. Wähle Branch: main
5. Klicke: "Run workflow"

### 4. APK herunterladen

Nach erfolgreichem Build:
1. Gehe zu: Actions Tab
2. Klicke auf den Workflow Run
3. Scrolle zu: **Artifacts**
4. Download: `hazebot-admin-test-release.apk`

---

## 🔐 Benutzer-Login:

**Admin (inventory69):**
- Username: `inventory69`
- Password: `x8vDJ1FHkkM0s7`

**Test User (duke):**
- Username: `duke`
- Password: `eLourKNqRyh7x4`

---

## 📱 APK Installation:

1. APK auf Android Gerät übertragen
2. "Installation aus unbekannten Quellen" erlauben
3. APK installieren
4. App öffnen
5. Mit einem der obigen Benutzer einloggen

---

## 🔄 Weitere Benutzer hinzufügen:

In `/home/liq/gitProjects/HazeBot/.env`:
```env
API_EXTRA_USERS=duke:eLourKNqRyh7x4,alice:password123,bob:secret456
```

Format: `username:password,username2:password2`

---

## 🏷️ Release erstellen:

Um eine GitHub Release mit APK zu erstellen:
```bash
cd /home/liq/gitProjects/HazeBot-Admin
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions wird automatisch:
1. Test-APK bauen
2. GitHub Release erstellen
3. APK zur Release hinzufügen

---

## ⚠️ Wichtig:

- Die APKs sind für **TEST** konfiguriert
- Sie verbinden sich mit: `https://test-hazebot-admin.hzwd.xyz/api`
- Lokale `.env` wird **nicht** committed (ist in `.gitignore`)
- GitHub Secret wird **verschlüsselt** gespeichert
