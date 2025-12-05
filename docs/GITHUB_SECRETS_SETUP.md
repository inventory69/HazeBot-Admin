# GitHub Secrets Setup für HazeBot-Admin

## 📋 Übersicht

Die GitHub Actions Workflow benötigt folgende Secrets, um die App korrekt zu bauen:

## 🔑 Erforderliche Secrets

### 1. API-Konfiguration

| Secret Name | Beschreibung | Beispiel |
|------------|--------------|----------|
| `API_BASE_URL` | **ERFORDERLICH** - Base URL des HazeBot API Servers | `https://your-domain.com/api` |
| `IMAGE_PROXY_URL` | Optional - Image Proxy URL für CORS-freies Laden | `https://your-domain.com/api/proxy/image` |
| `PROD_MODE` | **ERFORDERLICH** - Production Mode (true/false) | `true` oder `false` |

### 2. Android Signing (nur für Release Builds)

| Secret Name | Beschreibung |
|------------|--------------|
| `KEYSTORE_BASE64` | Base64-encoded Android Keystore (.jks) |
| `KEYSTORE_PASSWORD` | Keystore Passwort |
| `KEY_ALIAS` | Key Alias |
| `KEY_PASSWORD` | Key Passwort |

### 3. Firebase (optional, für Push Notifications)

| Secret Name | Beschreibung |
|------------|--------------|
| `GOOGLE_SERVICES_JSON` | Kompletter Inhalt der `google-services.json` Datei |

---

## ⚙️ Secrets hinzufügen

### Schritt 1: GitHub Repository öffnen
1. Gehe zu deinem Repository: `https://github.com/YOUR_USERNAME/HazeBot-Admin`
2. Klicke auf **Settings** (Zahnrad-Symbol)
3. In der linken Sidebar: **Secrets and variables** → **Actions**

### Schritt 2: Secret hinzufügen
1. Klicke auf **New repository secret**
2. Name eingeben (z.B. `PROD_MODE`)
3. Value eingeben (z.B. `true`)
4. Klicke auf **Add secret**

---

## 🎯 PROD_MODE Verhalten

### PROD_MODE=true (Production)
```env
PROD_MODE=true
```
- **App Name**: Chillventory
- **Environment**: Production
- **Theme**: Production Farben
- **User-Agent**: `Chillventory/1.0`

### PROD_MODE=false (Development)
```env
PROD_MODE=false
```
- **App Name**: Testventory
- **Environment**: Development
- **Theme**: Development Farben
- **User-Agent**: `Testventory/1.0`

---

## 🔍 Verifikation

### Nach dem Build prüfen:

1. **In der App:**
   - Öffne Settings (Einstellungen)
   - Unter "App Information" siehst du:
     - **App Name**: Chillventory (PROD) oder Testventory (DEV)
     - **Environment**: Production oder Development

2. **Im APK Namen:**
   - Production: `hazebot-admin-test-release.apk` (mit PROD_MODE=true)
   - Development: `hazebot-admin-test-debug.apk` (mit PROD_MODE=false)

3. **In den GitHub Actions Logs:**
   ```
   ✅ .env file created with configuration
      📦 API_BASE_URL: https://your-domain.com/api
      🖼️  IMAGE_PROXY_URL: https://your-domain.com/api/proxy/image
      🔧 PROD_MODE: true
   ```

---

## 🐛 Troubleshooting

### Problem: App zeigt immer "Testventory"
**Ursache:** `PROD_MODE` Secret ist nicht gesetzt oder falsch konfiguriert

**Lösung:**
1. Prüfe in GitHub Settings → Secrets → Actions ob `PROD_MODE` existiert
2. Wert muss **exakt** `true` sein (lowercase, keine Anführungszeichen)
3. Wenn Secret geändert wird: Neuen Workflow-Run auslösen
4. Im Workflow Log prüfen ob `PROD_MODE: true` angezeigt wird

### Problem: "Context access might be invalid: PROD_MODE"
**Ursache:** VS Code Linter erkennt GitHub Actions Syntax nicht korrekt

**Lösung:** Ignorieren - das ist ein false-positive. GitHub Actions akzeptiert `${{ secrets.PROD_MODE }}` Syntax.

### Problem: API_BASE_URL nicht gefunden
**Ursache:** Secret `API_BASE_URL` fehlt

**Lösung:**
1. Workflow schlägt mit Error fehl: "Secret API_BASE_URL is not set!"
2. Secret in Repository Settings hinzufügen
3. Workflow neu starten

---

## 📝 Lokale Entwicklung

Für lokale Entwicklung erstelle eine `.env` Datei im Root:

```bash
# Copy example and edit
cp .env.example .env
```

Dann editiere `.env`:
```env
API_BASE_URL=https://your-domain.com/api
IMAGE_PROXY_URL=https://your-domain.com/api/proxy/image
GITHUB_REPO_URL=https://github.com/inventory69/HazeBot-Admin
PROD_MODE=false  # Verwende false für lokale Entwicklung
```

---

## 🚀 Quick Start Checklist

- [ ] `API_BASE_URL` Secret gesetzt
- [ ] `PROD_MODE` Secret gesetzt (`true` für Production, `false` für Dev)
- [ ] `IMAGE_PROXY_URL` Secret gesetzt (optional)
- [ ] Firebase `GOOGLE_SERVICES_JSON` Secret gesetzt (optional)
- [ ] Android Signing Secrets gesetzt (nur für Release)
- [ ] Workflow ausgeführt und Logs geprüft
- [ ] APK heruntergeladen und App Name geprüft

---

## 📚 Siehe auch

- [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) - Vollständige CI/CD Dokumentation
- [BUILDING.md](BUILDING.md) - Build-Anweisungen
- [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) - Setup-Checkliste
- [Documentation Index](README.md) - Alle Dokumentationen
