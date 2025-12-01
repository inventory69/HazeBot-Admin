# HazeBot Admin - Complete Features Documentation

Comprehensive list of all features available in HazeBot Admin Panel.

---

## 🎮 User Features (Available to All Users)

### HazeHub
**Community feed with recent activity**
- Latest memes from Reddit/Lemmy
- Recent Rocket League rank-ups
- Profile avatars and usernames
- Direct links to Discord messages
- Pull-to-refresh for updates
- Lazy loading with pagination

### Gaming Hub
**See who's online and ready to play**
- Live online status from Discord
- Filter by game/activity
- Send game request notifications via bot
- See current activities/games
- Profile avatars and nicknames
- Real-time updates via WebSocket

### Rocket League Manager
**Personal RL account management**
- Add/edit/remove RL accounts
- Set primary account
- Platform selection (Epic, Steam, PlayStation, Xbox, Switch)
- Rank display with tier icons
- Post rank updates to Discord
- View personal RL statistics

### Meme Generator
**Create memes with 100+ templates**
- Browse popular meme templates
- Search templates by name
- Add custom top/bottom text
- Text size and position adjustment
- Font customization (Impact, Arial, Comic Sans, etc.)
- Text color and outline
- Preview before generation
- Download generated memes
- Share directly to Discord channels
- View generation history

### Profile
**Personal profile and statistics**
- Discord avatar and username
- Current Rocket League rank badge
- User roles with colored badges
- Opt-in roles management (add/remove)
- Activity statistics:
  - Total messages sent
  - Commands used
  - Memes generated
  - Time in voice channels
- Account details:
  - Discord join date
  - Server join date
  - Account creation date
- Custom statistics from bot modules
- Push notification settings
- Theme toggle (light/dark/system)

---

## ⚙️ Admin Features (Admin/Moderator Only)

### General Configuration
**Bot-wide settings and behavior**
- **Channels Configuration:**
  - Meme channel selection
  - Rules channel
  - Welcome channel
  - Log channels (mod, public)
  - Notification channels
- **Roles Configuration:**
  - Admin roles
  - Moderator roles
  - Muted role
  - Auto-assignable roles
  - Opt-in roles
- **Bot Settings:**
  - Command prefix
  - Bot status message
  - Auto-moderation settings
  - Logging levels
- **Welcome Messages:**
  - Custom welcome text
  - Welcome embed settings
  - DM welcome toggle
- **Reaction Roles:**
  - Configure emoji-to-role mappings
  - Multiple reaction role messages
- Live preview of changes
- Validation before saving
- Automatic bot restart if needed

### Meme Configuration
**Control meme sources and settings**
- **Subreddit Management:**
  - Add/remove subreddits
  - Enable/disable individual sources
  - Set posting frequency
  - NSFW filter toggle
  - Minimum score threshold
- **Lemmy Communities:**
  - Add Lemmy instances
  - Community selection
  - NSFW filtering
  - Instance health check
- **Daily Meme Preferences:**
  - Set posting schedule (time + timezone)
  - Select active subreddits
  - Select active Lemmy communities
  - Enable/disable daily posts
- **Meme Template Library:**
  - Browse 100+ templates
  - Search templates
  - Add custom templates (URL)
  - Edit template metadata
  - Delete unused templates
  - Test template generation

### Rocket League Configuration
**Server-wide RL settings**
- **Channels:**
  - Rank update channel
  - Congratulations channel
  - Stats channel
- **Rank Roles:**
  - Map RL ranks to Discord roles
  - Auto-role assignment on rank updates
  - Role hierarchy management
- **Update Settings:**
  - Minimum rank change to post
  - Congratulations message templates
  - Embed color schemes
- **Account Limits:**
  - Max accounts per user
  - Verification requirements

### Cog Manager
**Load/unload/reload bot cogs (modules)**
- View all available cogs
- See loaded/unloaded status
- Load new cogs on demand
- Unload running cogs
- Reload cogs without restart
- Cog dependencies display
- Error messages for failed operations
- Category organization:
  - Core (essential cogs)
  - Moderation
  - Fun & Games
  - Utility
  - Admin Tools
  - Custom

### Support Tickets
**Manage user support requests**
- **Ticket List:**
  - View all open tickets
  - Filter by status (open/closed)
  - See ticket priority
  - Sort by date/priority
  - Ticket count badges
- **Ticket Details:**
  - Full message history
  - Ticket metadata (creator, date, category)
  - Attachment previews
  - User information
- **Ticket Actions:**
  - Reply to tickets (posts to Discord)
  - Close tickets
  - Reopen closed tickets
  - Assign to moderator
  - Set priority level
- **Real-time Updates:**
  - Live message notifications
  - WebSocket-based updates
  - Toast notifications for new messages

### Active Sessions Monitor
**See who's using the admin panel**
- Current active sessions
- User information (Discord name, ID)
- Device information (platform, device model)
- IP address (masked for privacy)
- Session duration
- Last activity timestamp
- Active endpoint usage
- Real-time updates (WebSocket)
- Kick users (force logout)
- Session analytics:
  - Peak usage times
  - Most used features
  - Average session length

### Log Viewer
**Browse and search bot logs**
- **Log Levels:**
  - DEBUG - Development info
  - INFO - General information
  - WARNING - Potential issues
  - ERROR - Actual errors
  - CRITICAL - Severe problems
- **Filtering:**
  - Filter by log level
  - Filter by time range (today, 7d, 30d, all)
  - Filter by module/cog
  - Search log content
- **Display Options:**
  - Timestamp display
  - Color-coded levels
  - Expandable stack traces
  - Line numbers
- **Actions:**
  - Refresh logs
  - Clear log filters
  - Export logs to file
  - Auto-scroll to bottom
- Pagination for large log files
- Real-time log streaming (optional)

### Analytics Dashboard
**Track admin panel usage (Admin only)**
- **User Metrics:**
  - Total unique users
  - Active users (7d/30d)
  - New user signups
  - User retention rate
- **Session Analytics:**
  - Total sessions
  - Average session duration
  - Sessions per day/week/month
  - Peak usage times (24h heatmap)
- **Feature Usage:**
  - Top 10 most used features
  - Endpoint call statistics
  - Feature adoption rate
  - Screen navigation patterns
- **Device Statistics:**
  - Platform breakdown (Android/iOS/Web/Desktop)
  - Device models
  - App version distribution
  - OS version distribution
- **Charts & Visualizations:**
  - User growth over time (line chart)
  - Device distribution (pie chart)
  - Hourly activity (bar chart)
  - Recent sessions table
- **Filters:**
  - Time range (7d/30d/90d/all)
  - Auto-refresh toggle
  - Export to JSON

---

## 🎨 UI/UX Features

### Navigation
- **Hybrid Navigation:**
  - Bottom tab bar for user features
  - Navigation rail for admin features
  - Admin toggle button (show/hide admin panel)
  - Profile button (opens bottom sheet)
- **Bottom Tabs (Users):**
  - HazeHub (🏠)
  - Gaming Hub (🎮)
  - Rocket League (🚀)
  - Memes (😂)
- **Admin Rail (Admins):**
  - Dashboard
  - General Config
  - Meme Config
  - RL Config
  - Cog Manager
  - Tickets
  - Monitoring
  - Logs

### Material Design 3
- **Dynamic Theming:**
  - Android 16 Monet color extraction
  - System wallpaper-based colors
  - Automatic color harmonization
- **Color Scheme:**
  - Primary, Secondary, Tertiary colors
  - Surface variants (low/medium/high/highest)
  - Dynamic text colors for contrast
- **Elevation:**
  - Flat design (elevation 0)
  - Depth through color, not shadows
- **Typography:**
  - Material Design 3 type scale
  - Responsive font sizes
  - Proper text hierarchy

### Animations
- **Hero Animations:**
  - Profile avatars
  - Meme images
  - Rank badges
- **Page Transitions:**
  - Fade transitions
  - Slide transitions
  - Shared element transitions
- **Micro-interactions:**
  - Button ripple effects
  - Pull-to-refresh animation
  - Loading skeletons
  - Smooth scroll animations

### Responsive Design
- **Mobile (< 600dp):**
  - Bottom navigation
  - Single column layout
  - Compact cards
  - Stacked forms
- **Tablet (600-1200dp):**
  - Navigation rail
  - Two column layout
  - Larger cards
  - Side-by-side forms
- **Desktop (> 1200dp):**
  - Persistent navigation rail
  - Multi-column layout
  - Maximum content width
  - Keyboard shortcuts

### Accessibility
- **Screen Reader Support:**
  - Semantic labels
  - Descriptive hints
  - Announcement regions
- **High Contrast:**
  - Sufficient color contrast ratios
  - Focus indicators
  - Clear state changes
- **Keyboard Navigation:**
  - Tab order
  - Focus management
  - Keyboard shortcuts

---

## 🔐 Authentication Features

### Login Methods
- **Discord OAuth2:**
  - One-click login
  - Automatic profile sync
  - Avatar and username retrieval
  - Role-based access control
- **Username/Password:**
  - Fallback authentication
  - Local account support
  - Password requirements
  - "Remember me" option

### Session Management
- **JWT Tokens:**
  - Access token (short-lived)
  - Refresh token (long-lived)
  - Automatic token refresh
  - Secure token storage
- **Session Persistence:**
  - Local storage (web)
  - Secure storage (mobile)
  - Cross-tab sync
- **Security:**
  - HTTPS enforcement
  - Token expiration
  - Automatic logout on token invalidation
  - Session timeout (configurable)

### Permissions
- **Role-Based Access:**
  - User role (default)
  - Moderator role (tickets, logs)
  - Admin role (full access)
- **Feature Gating:**
  - Admin features hidden for non-admins
  - Permission checks on API calls
  - Graceful permission denied messages

---

## 🔔 Push Notifications (Mobile)

### Firebase Cloud Messaging
- **Notification Types:**
  - New tickets
  - Ticket replies
  - Ticket status changes
  - Gaming requests
  - Mention notifications
  - System alerts
- **Features:**
  - Rich notifications (images, actions)
  - Notification channels (Android)
  - Sound/vibration customization
  - Notification badges
- **Settings:**
  - Enable/disable per type
  - Quiet hours
  - Priority notifications
  - Do Not Disturb sync

---

## 🌐 Real-Time Features

### WebSocket Integration
- **Live Updates:**
  - Gaming Hub online status
  - Active sessions monitor
  - Ticket messages
  - Log streaming
- **Connection Management:**
  - Automatic reconnection
  - Connection status indicator
  - Offline mode support
  - Buffered messages on reconnect

---

## 🛠️ Developer Features

### Debug Tools
- **Debug Info:**
  - App version display
  - API connection status
  - Current user info
  - Device information
- **Developer Options:**
  - API request logging
  - Performance metrics
  - Cache statistics
  - Error reports

### Testing
- **API Testing:**
  - Manual endpoint testing
  - Request/response inspection
  - Token validation
- **UI Testing:**
  - Widget testing support
  - Integration testing
  - E2E testing

---

## 📱 Platform-Specific Features

### Web
- **PWA Support:**
  - Install to home screen
  - Offline mode (limited)
  - App manifest
- **Web-Specific:**
  - Right-click context menus
  - Browser back/forward navigation
  - URL routing

### Android
- **Android-Specific:**
  - Material You theming
  - Adaptive icons
  - Splash screen
  - Share target
  - System navigation gestures
- **Notifications:**
  - Notification channels
  - Notification importance
  - Grouped notifications

### Linux Desktop
- **Desktop-Specific:**
  - Native window management
  - Keyboard shortcuts
  - System tray icon (optional)
  - File picker dialogs

---

## 🎯 Planned Features

- [ ] **Analytics Dashboard** - External HTML dashboard with usage statistics
- [ ] **Bulk Actions** - Mass operations on tickets, users, etc.
- [ ] **Export/Import** - Configuration backup/restore
- [ ] **Advanced Filters** - More filtering options across all screens
- [ ] **Custom Commands** - Configure custom bot commands
- [ ] **Audit Log** - Track all admin actions
- [ ] **API Rate Limiting** - Visual rate limit indicators
- [ ] **Scheduled Actions** - Schedule bot actions
- [ ] **Multi-Server** - Manage multiple Discord servers
- [ ] **Plugin System** - Third-party plugin support
