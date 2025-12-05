# Plan: User Ticket Close/Reopen Funktionen

## 📋 Zusammenfassung

Normale User sollen ihre eigenen Tickets closen und wieder öffnen können (begrenzt auf 3x Reopen).

## ✅ Was bereits vorhanden ist

### Backend (HazeBot API)
1. **API Endpoints existieren bereits:**
   - `POST /api/tickets/<ticket_id>/close` - Ticket schließen
   - `POST /api/tickets/<ticket_id>/reopen` - Ticket wieder öffnen
   
2. **Berechtigungen bereits korrekt:**
   - `is_allowed_for_ticket_actions()` in `Cogs/TicketSystem.py` Zeile 98:
     - **Close**: Creator, Admins oder Moderators ✅
     - **Reopen**: Creator, Admins oder Moderators ✅
   - Reopen limitiert auf 3 Mal (Zeile 868)

3. **API Permission Decorators:**
   - `close_ticket_endpoint`: `require_permission("all")` - bedeutet alle authentifizierten User ✅
   - `reopen_ticket_endpoint`: `require_permission("all")` - bedeutet alle authentifizierten User ✅

### Discord Bot
- User können im Discord bereits ihre Tickets closen/reopenen via Buttons
- Reopen Count wird getrackt und auf 3 limitiert

### Frontend Admin Screen
- `lib/screens/admin/ticket_detail_dialog.dart` hat bereits:
  - `_closeTicket()` Methode (Zeile 334)
  - `_reopenTicket()` Methode (Zeile 378)
  - UI Buttons für beide Aktionen
  - Close mit optionaler Message

### Frontend API Service
- `lib/services/api_service.dart` hat bereits:
  - `closeTicket(String ticketId, {String? closeMessage})` (Zeile 1598)
  - `reopenTicket(String ticketId)` (Zeile 1610)

## 🚧 Was fehlt

### User Tickets Screen
Die Datei `lib/screens/user/tickets_screen.dart` zeigt nur:
- Liste der eigenen Tickets (My Tickets Tab)
- Create New Ticket Tab
- `_TicketDetailScreen` Widget (Zeile 892) - zeigt nur Chat, **KEINE** Action Buttons

**Problem:** User sehen zwar ihre Tickets und können Nachrichten schreiben, aber haben keine Buttons zum Close/Reopen.

## 📝 Implementierungsplan

### Phase 1: User Ticket Detail Screen erweitern

**Datei:** `lib/screens/user/tickets_screen.dart`

#### 1.1 _TicketDetailScreen zu StatefulWidget ändern
- Aktuell: StatelessWidget (Zeile 892)
- Neu: StatefulWidget mit State Management

#### 1.2 Action Buttons hinzufügen
**Für offene Tickets (Status: 'Open' oder 'Claimed'):**
```dart
// Close Button
FilledButton.icon(
  onPressed: _closeTicket,
  icon: Icon(Icons.lock),
  label: Text('Close Ticket'),
  style: FilledButton.styleFrom(
    backgroundColor: Colors.red,
  ),
)
```

**Für geschlossene Tickets (Status: 'Closed'):**
```dart
// Reopen Button (nur wenn reopen_count < 3)
if (ticket.reopenCount < 3)
  FilledButton.icon(
    onPressed: _reopenTicket,
    icon: Icon(Icons.lock_open),
    label: Text('Reopen Ticket'),
  )

// Reopen Counter anzeigen
if (ticket.reopenCount > 0)
  Text('Reopened ${ticket.reopenCount}/3 times')
```

#### 1.3 Methoden implementieren

**_closeTicket():**
```dart
Future<void> _closeTicket() async {
  // 1. Optional: Close Message Dialog (wie im Admin Screen)
  final closeMessage = await showDialog<String>(
    context: context,
    builder: (context) => _CloseMessageDialog(),
  );
  
  if (closeMessage == null) return;
  
  // 2. API Call
  await ApiService().closeTicket(
    ticket.ticketId,
    closeMessage: closeMessage.isEmpty ? null : closeMessage,
  );
  
  // 3. Refresh & Navigate back
  if (mounted) {
    Navigator.pop(context); // Zurück zur Ticket-Liste
    // Ticket-Liste wird automatisch refreshed
  }
}
```

**_reopenTicket():**
```dart
Future<void> _reopenTicket() async {
  // 1. Confirmation Dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reopen Ticket'),
      content: Text(
        'Do you want to reopen this ticket?\n'
        'Reopens remaining: ${3 - ticket.reopenCount}/3'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Reopen'),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  // 2. API Call
  await ApiService().reopenTicket(ticket.ticketId);
  
  // 3. Refresh & Navigate back
  if (mounted) {
    Navigator.pop(context);
  }
}
```

#### 1.4 _CloseMessageDialog Widget
- Copy from `lib/screens/admin/ticket_detail_dialog.dart` (Zeile 1326)
- Optionale Nachricht beim Schließen
- Max 500 Zeichen

### Phase 2: Ticket Model erweitern (falls nötig)

**Datei:** `lib/models/ticket.dart`

Prüfen ob `reopenCount` bereits im Model ist:
```dart
final int reopenCount; // Anzahl wie oft reopened
```

Falls nicht vorhanden: hinzufügen.

### Phase 3: UI/UX Verbesserungen

#### 3.1 Status Badge in Ticket Liste
- Zeige visuell ob Ticket offen/geschlossen ist
- Farbcodierung: Grün (Open), Orange (Claimed), Rot (Closed)

#### 3.2 Reopen Counter
- Zeige in der Ticket-Detail-Ansicht wie oft noch reopened werden kann
- Warning wenn Limit erreicht: "Cannot reopen again (limit reached)"

#### 3.3 Loading States
- Loading Indicator während API Calls
- Disable Buttons während Verarbeitung

#### 3.4 Error Handling
- SnackBar bei Fehlern
- Spezifische Fehlermeldungen:
  - "Ticket already closed"
  - "Ticket cannot be reopened more than 3 times"
  - "Network error"

### Phase 4: Testing

#### 4.1 Test Cases
1. **Close Ticket:**
   - ✅ User kann eigenes offenes Ticket closen
   - ✅ Close Message wird gespeichert
   - ✅ Ticket Status wird auf "Closed" gesetzt
   - ✅ User kann nach Close keine Nachrichten mehr senden

2. **Reopen Ticket:**
   - ✅ User kann eigenes geschlossenes Ticket reopenen
   - ✅ Reopen Count wird inkrementiert
   - ✅ Nach 3x Reopen: Button disabled + Warning
   - ✅ Nach Reopen kann User wieder Nachrichten senden

3. **Berechtigungen:**
   - ❌ User kann NICHT Tickets von anderen Usern closen/reopenen
   - ✅ Admin kann alle Tickets closen/reopenen (bereits vorhanden)

4. **UI:**
   - ✅ Buttons erscheinen zur richtigen Zeit
   - ✅ Loading States funktionieren
   - ✅ Error Messages werden angezeigt
   - ✅ Navigation funktioniert

## 📂 Betroffene Dateien

### Zu ändern:
1. ✏️ `lib/screens/user/tickets_screen.dart` - Hauptänderung
   - `_TicketDetailScreen` zu StatefulWidget
   - Action Buttons hinzufügen
   - `_closeTicket()` und `_reopenTicket()` Methoden
   - `_CloseMessageDialog` Widget

### Ggf. zu ändern:
2. ✏️ `lib/models/ticket.dart` - Falls `reopenCount` fehlt

### Bereits vorhanden (keine Änderung):
3. ✅ `lib/services/api_service.dart` - API Calls vorhanden
4. ✅ `HazeBot/api/ticket_routes.py` - Backend Endpoints vorhanden
5. ✅ `HazeBot/Cogs/TicketSystem.py` - Berechtigungen korrekt

## ⏱️ Aufwandsschätzung

**Gesamt: ~2-3 Stunden**

- Phase 1: Widget Refactoring & UI: **1-1.5h**
  - StatefulWidget Conversion: 15min
  - Action Buttons UI: 30min
  - `_closeTicket()` Methode: 20min
  - `_reopenTicket()` Methode: 20min
  - `_CloseMessageDialog`: 10min (Copy & Adapt)
  
- Phase 2: Model Check: **10min**
  - Prüfen ob `reopenCount` vorhanden
  - Falls nötig hinzufügen

- Phase 3: UI/UX Polish: **30-45min**
  - Status Badges
  - Loading States
  - Error Handling
  - Reopen Counter Display

- Phase 4: Testing: **30min**
  - Manuelle Tests
  - Edge Cases prüfen

## ✅ Vorteile dieser Implementierung

1. **Minimal Invasiv:** Nur Frontend-Änderungen nötig
2. **Backend Ready:** API Endpoints bereits vorhanden und getestet
3. **Konsistent:** Nutzt gleiche API Calls wie Admin Screen
4. **Sicher:** Berechtigungen werden auf Backend geprüft
5. **User Experience:** User können Tickets selbst verwalten ohne Admin/Mod

## 🔒 Sicherheit

- ✅ Backend validiert User ID vs. Ticket Creator ID
- ✅ Reopen Limit wird auf Backend erzwungen
- ✅ JWT Token erforderlich für API Calls
- ✅ Keine zusätzlichen Security Concerns

## 📱 UI Mockup (Textbeschreibung)

### Offenes Ticket (_TicketDetailScreen):
```
┌─────────────────────────────┐
│  Ticket #123                │
│  Status: Open 🟢            │
├─────────────────────────────┤
│                             │
│  [Chat Messages hier]       │
│                             │
├─────────────────────────────┤
│  [Message Input Field]      │
│  [Send Button]              │
├─────────────────────────────┤
│  [🔒 Close Ticket] (Red)    │
└─────────────────────────────┘
```

### Geschlossenes Ticket (_TicketDetailScreen):
```
┌─────────────────────────────┐
│  Ticket #123                │
│  Status: Closed 🔴          │
│  Reopened 1/3 times         │
├─────────────────────────────┤
│                             │
│  [Chat History (read-only)] │
│                             │
├─────────────────────────────┤
│  [🔓 Reopen Ticket] (Blue)  │
└─────────────────────────────┘
```

### Geschlossenes Ticket (Limit erreicht):
```
┌─────────────────────────────┐
│  Ticket #123                │
│  Status: Closed 🔴          │
│  ⚠️ Reopen limit reached    │
│  (3/3 reopens used)         │
├─────────────────────────────┤
│                             │
│  [Chat History (read-only)] │
│                             │
├─────────────────────────────┤
│  ℹ️ Cannot reopen again     │
│  Please create a new ticket │
└─────────────────────────────┘
```

## 🎯 Nächste Schritte

1. ✅ Plan Review (Done - dieser Plan)
2. ⏳ `lib/models/ticket.dart` prüfen auf `reopenCount`
3. ⏳ `_TicketDetailScreen` zu StatefulWidget refactoren
4. ⏳ Action Buttons implementieren
5. ⏳ `_closeTicket()` und `_reopenTicket()` Methoden
6. ⏳ UI/UX Polish
7. ⏳ Testing
8. ⏳ Dokumentation Update

## 💡 Hinweise

- Die Admin Screen Implementierung kann als Referenz dienen
- Error Handling sollte spezifisch sein (z.B. "Already closed", "Reopen limit")
- Loading States wichtig für User Feedback
- Reopen Counter prominent anzeigen wenn > 0
