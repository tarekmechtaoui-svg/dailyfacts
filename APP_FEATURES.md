# Daily Facts App - Features Overview

## Screen Organization

### 1. Categories Screen (Tab 1)
- **Icon**: Category icon
- **Purpose**: Select topics to receive daily facts
- **Features**:
  - Grid layout showing all available categories
  - Visual selection with checkmarks
  - Counter showing selected categories
  - Confirmation popup when adding a category:
    - Green checkmark icon
    - Message: "You will receive daily facts about [Category]"
    - Clean, friendly confirmation dialog

### 2. Facts Screen (Tab 2)
- **Icon**: Lightbulb icon
- **Purpose**: View all daily facts from selected categories
- **Features**:
  - List view of all facts
  - Each fact shows:
    - Category icon and name
    - Fact text
    - Date added
  - Pull-to-refresh functionality
  - Empty state message if no categories selected
  - Sorted by newest first

### 3. Settings Screen (Tab 3)
- **Icon**: Settings icon
- **Purpose**: Manage account and notification preferences
- **Features**:
  - Account section showing user email
  - Notifications toggle:
    - Enable/disable push notifications
    - Request permission when enabling
  - About section showing app version
  - Sign out button with confirmation dialog

## Navigation

- **Bottom Navigation Bar**: Always visible, allows quick switching between tabs
- **State Persistence**: Each tab maintains its state when switching
- **AppBar**: Consistent header with "Daily Facts" title

## Design

- **Color Scheme**: Blue primary color (Colors.blue.shade600)
- **Typography**: Material Design 3
- **Spacing**: Consistent padding and margins
- **Icons**: Material icons with active/inactive states
- **Animations**: Smooth transitions when selecting categories

## Data Flow

1. **Authentication**: Users must be logged in to access the app
2. **Category Selection**: Subscriptions are saved to Supabase
3. **Facts Display**: Facts filtered based on user subscriptions
4. **Notifications**: Controlled via OneSignal + notification preferences

## Technical Architecture

- **State Management**: StatefulWidget (simple, scoped state)
- **Data Persistence**: Supabase database
- **Push Notifications**: OneSignal + Firebase Cloud Messaging
- **Database Tables**:
  - `subjects`: Available categories
  - `daily_facts`: All daily facts
  - `user_subjects`: User subscriptions
  - `auth.users`: User accounts
