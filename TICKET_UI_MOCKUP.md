# 📱 UI Mockup: User Ticket Close/Reopen Buttons

## Aktuelle Struktur (VORHER)

```
┌─────────────────────────────────────────┐
│ ← Ticket #123                           │ AppBar
├─────────────────────────────────────────┤
│ 📋 Support    🟢 Open                   │
│                                          │ Header Container
│ ℹ️ Subject: Login Issue ▼               │ (grauer Bereich)
│   Description: Cannot login...          │
│                                          │
│ 👤 Assigned to: Moderator123            │
├─────────────────────────────────────────┤
│                                          │
│ 💬 Chat Message 1                       │
│ 💬 Chat Message 2                       │
│ 💬 Chat Message 3                       │ TicketChatWidget
│ ...                                      │ (scrollbar)
│                                          │
│ [Type your message here...]             │ Message Input
│                          [Send Button]  │
└─────────────────────────────────────────┘
```

**Problem:** Keine Möglichkeit zum Closen!

---

## Neue Struktur - Option 1: Buttons UNTER dem Chat (EMPFOHLEN ⭐)

```
┌─────────────────────────────────────────┐
│ ← Ticket #123                           │ AppBar
├─────────────────────────────────────────┤
│ 📋 Support    🟢 Open                   │ Header
├─────────────────────────────────────────┤
│                                          │
│ 💬 Chat Messages...                     │ Chat
│                                          │
│ [Type message...] [Send]                │ Input
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │  🔒 Close Ticket                    │ │ ← NEU!
│ └─────────────────────────────────────┘ │ Action Button
│                                          │ Container
└─────────────────────────────────────────┘
```

**Bei geschlossenem Ticket:**
```
├─────────────────────────────────────────┤
│ 📋 Support    🔴 Closed                 │
│ 📊 Reopened 1/3 times                   │ ← Reopen Counter
├─────────────────────────────────────────┤
│                                          │
│ 💬 Chat History (read-only)             │
│                                          │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │  🔓 Reopen Ticket                   │ │ ← NEU!
│ └─────────────────────────────────────┘ │ Reopen Button
│                                          │ (Blau)
└─────────────────────────────────────────┘
```

**Bei Reopen-Limit erreicht:**
```
├─────────────────────────────────────────┤
│ 📋 Support    🔴 Closed                 │
│ ⚠️ Reopen limit reached (3/3)           │ ← Warning
├─────────────────────────────────────────┤
│                                          │
│ 💬 Chat History (read-only)             │
│                                          │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ ℹ️ Cannot reopen again               │ │
│ │ Please create a new ticket           │ │ ← Info Box
│ └─────────────────────────────────────┘ │ (disabled)
└─────────────────────────────────────────┘
```

---

## Option 2: Buttons in der AppBar (Alternative)

```
┌─────────────────────────────────────────┐
│ ← Ticket #123              🔒 Close  │ │ ← Button in AppBar
├─────────────────────────────────────────┤
│ 📋 Support    🟢 Open                   │
├─────────────────────────────────────────┤
│ 💬 Chat...                              │
│ [Input]                                 │
└─────────────────────────────────────────┘
```

**Nachteil:** Weniger prominent, könnte übersehen werden.

---

## Option 3: Floating Action Button (Alternative)

```
┌─────────────────────────────────────────┐
│ ← Ticket #123                           │
├─────────────────────────────────────────┤
│ 💬 Chat...                              │
│                                          │
│                              ╭─────╮    │
│                              │ 🔒  │    │ ← FAB
│                              ╰─────╯    │
└─────────────────────────────────────────┘
```

**Nachteil:** Könnte Chat-Inhalte überdecken.

---

## 🎨 Detaillierte UI-Spezifikation (Option 1 - Empfohlen)

### Scaffold Struktur

```dart
Scaffold(
  appBar: AppBar(...),
  body: Column(
    children: [
      // 1. Header Container (unchanged)
      Container(...),
      
      Divider(),
      
      // 2. Chat Widget (unchanged)
      Expanded(
        child: TicketChatWidget(...),
      ),
      
      // 3. ACTION BUTTONS SECTION (NEU!)
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
        ),
        child: _buildActionButtons(),
      ),
    ],
  ),
)
```

### Button Designs

#### Close Button (Offenes Ticket)
```dart
SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: _closeTicket,
    icon: Icon(Icons.lock),
    label: Text('Close Ticket'),
    style: FilledButton.styleFrom(
      backgroundColor: Colors.red[700],
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
)
```

**Visuell:**
```
┌─────────────────────────────────────┐
│  🔒  Close Ticket                   │  ← Roter Button
└─────────────────────────────────────┘
```

#### Reopen Button (Geschlossenes Ticket)
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Reopen Counter Badge
    if (ticket.reopenCount > 0)
      Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            SizedBox(width: 8),
            Text(
              'Reopened ${ticket.reopenCount}/3 times',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ],
        ),
      ),
    
    // Reopen Button
    FilledButton.icon(
      onPressed: ticket.reopenCount < 3 ? _reopenTicket : null,
      icon: Icon(Icons.lock_open),
      label: Text(
        ticket.reopenCount < 3 
          ? 'Reopen Ticket (${3 - ticket.reopenCount} left)'
          : 'Reopen Limit Reached',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.blue[700],
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  ],
)
```

**Visuell (1 Reopen):**
```
┌─────────────────────────────────────┐
│ ⓘ Reopened 1/3 times                │  ← Orange Info Box
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🔓  Reopen Ticket (2 left)         │  ← Blauer Button
└─────────────────────────────────────┘
```

**Visuell (Limit erreicht):**
```
┌─────────────────────────────────────┐
│ ⚠️ Reopen limit reached (3/3)       │  ← Rote Warning Box
│                                      │
│ You cannot reopen this ticket again.│
│ Please create a new ticket if you   │
│ still need assistance.               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🔓  Reopen Limit Reached           │  ← Disabled (grau)
└─────────────────────────────────────┘
```

---

## 💬 Dialogs

### Close Ticket Dialog
```
┌──────────────────────────────────┐
│ Close Ticket                   × │
├──────────────────────────────────┤
│                                   │
│ Add an optional closing message: │
│                                   │
│ ┌───────────────────────────────┐│
│ │ Thank you for reporting this. ││
│ │ The issue has been resolved.  ││
│ │                               ││
│ └───────────────────────────────┘│
│ 0/500 characters                  │
│                                   │
│           [Cancel]  [Close]       │
└──────────────────────────────────┘
```

### Reopen Confirmation Dialog
```
┌──────────────────────────────────┐
│ Reopen Ticket                  × │
├──────────────────────────────────┤
│                                   │
│ Do you want to reopen this        │
│ ticket?                           │
│                                   │
│ Reopens remaining: 2/3            │
│                                   │
│ The ticket will be reopened and   │
│ you can continue the conversation.│
│                                   │
│           [Cancel]  [Reopen]      │
└──────────────────────────────────┘
```

---

## 🎬 User Flow

### Close Ticket Flow
```
1. User öffnet eigenes Ticket
   → Status: Open
   → Sieht "🔒 Close Ticket" Button

2. User klickt "Close Ticket"
   → Dialog öffnet sich
   → Optional: Close Message eingeben

3. User klickt "Close"
   → Loading Indicator
   → API Call /api/tickets/{id}/close

4. Success
   → SnackBar: "✅ Ticket closed successfully"
   → Navigate back zur Ticket-Liste
   → Ticket Status jetzt "Closed"
```

### Reopen Ticket Flow
```
1. User öffnet eigenes geschlossenes Ticket
   → Status: Closed
   → Sieht "🔓 Reopen Ticket (3 left)" Button
   → Sieht Reopen Counter wenn > 0

2. User klickt "Reopen Ticket"
   → Confirmation Dialog
   → Zeigt verbleibende Reopens

3. User bestätigt
   → Loading Indicator
   → API Call /api/tickets/{id}/reopen

4. Success
   → SnackBar: "✅ Ticket reopened successfully"
   → Navigate back zur Ticket-Liste
   → Ticket Status jetzt "Open"
```

---

## 📊 State Diagram

```
┌─────────────────────────────────────────┐
│           TICKET STATE                  │
└─────────────────────────────────────────┘
          │
          │ User opens ticket
          ↓
    ┌──────────┐
    │   OPEN   │ ← Shows: Close Button
    └──────────┘
          │
          │ User clicks Close
          ↓
    ┌──────────┐
    │  CLOSED  │ ← Shows: Reopen Button (if < 3)
    └──────────┘
          │
          │ User clicks Reopen
          │ (reopen_count++)
          ↓
    ┌──────────┐
    │   OPEN   │ ← Shows: Close Button
    └──────────┘   + "Reopened 1/3 times" badge
          │
          │ ... repeat up to 3x ...
          ↓
    ┌──────────┐
    │  CLOSED  │ ← Shows: Disabled message
    └──────────┘   "Reopen limit reached (3/3)"
                   Cannot reopen anymore
```

---

## 🎨 Color Scheme

### Close Button
- Background: `Colors.red[700]` (Rot)
- Icon: `Icons.lock`
- Text: "Close Ticket"

### Reopen Button
- Background: `Colors.blue[700]` (Blau)
- Icon: `Icons.lock_open`
- Text: "Reopen Ticket (X left)"

### Reopen Counter Badge
- Background: `Colors.orange[50]`
- Border: `Colors.orange[300]`
- Text: `Colors.orange[900]`
- Icon: `Icons.info_outline`

### Warning (Limit Reached)
- Background: `Colors.red[50]`
- Border: `Colors.red[300]`
- Text: `Colors.red[900]`
- Icon: `Icons.warning_amber`

---

## 🔍 Responsive Design

### Mobile (< 600dp)
- Buttons: Full width
- Padding: 16px
- Button height: 48dp (Material touch target)

### Tablet/Desktop (> 600dp)
- Buttons: Full width (in ticket detail)
- Max width könnte begrenzt werden: 400px centered

---

## ✅ Warum Option 1 (Buttons unter Chat)?

1. **Prominent:** Immer sichtbar ohne scrollen
2. **Nicht störend:** Überdeckt keinen Chat-Inhalt
3. **Konsistent:** Ähnlich wie Admin Dialog Layout
4. **Klar getrennt:** Eigener Container = klare Action Section
5. **Mobile-friendly:** Leicht erreichbar am unteren Bildschirmrand
6. **Flexibel:** Platz für zusätzliche Info-Boxen (Reopen Counter)

---

## 📱 Screenshot-Ähnliche Darstellung

### Offenes Ticket auf Mobile
```
╔═══════════════════════════════════════╗
║ ←  Ticket #123                        ║
╠═══════════════════════════════════════╣
║ 📋 Support      🟢 Open               ║
║                                        ║
║ ℹ️ Subject: Cannot login ▼            ║
╠═══════════════════════════════════════╣
║                                        ║
║  Admin: How can I help you?           ║
║  ┗━ 2 hours ago                        ║
║                                        ║
║  You: I forgot my password            ║
║  ┗━ 1 hour ago                         ║
║                                        ║
║  Admin: I've reset it, check email    ║
║  ┗━ 30 minutes ago                     ║
║                                        ║
║ [Type your message here...      Send] ║
╠═══════════════════════════════════════╣
║ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║ ┃   🔒   Close Ticket              ┃ ║
║ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║
╚═══════════════════════════════════════╝
```

### Geschlossenes Ticket (1x Reopened)
```
╔═══════════════════════════════════════╗
║ ←  Ticket #123                        ║
╠═══════════════════════════════════════╣
║ 📋 Support      🔴 Closed             ║
╠═══════════════════════════════════════╣
║                                        ║
║  Admin: Issue resolved!                ║
║  ┗━ 1 day ago                          ║
║                                        ║
║  [This ticket has been closed]        ║
║                                        ║
╠═══════════════════════════════════════╣
║ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║ ┃ ⓘ Reopened 1/3 times             ┃ ║
║ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║
║                                        ║
║ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ║
║ ┃   🔓   Reopen Ticket (2 left)    ┃ ║
║ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ║
╚═══════════════════════════════════════╝
```

**Perfekt klar und prominent platziert!** ✅
