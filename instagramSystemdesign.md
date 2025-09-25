# Functional Requirements :- Instagram-Like App: 

## 1. Authentication & User Management
- User sign-up, login, and logout (email/phone)
- Social logins: Facebook, Google
- Manage account settings and privacy preferences

## 2. User Profile & Relationships
- User profile page with posts, followers, and following lists
- Follow/unfollow users
- Option for public or private accounts

## 3. Content Creation & Consumption
- Upload images and videos to feed
- Create and view Stories/Reels
- Edit captions, add hashtags and mentions
- Like, comment, and share posts
- Save or bookmark posts for later

## 4. Search & Discovery
- Search users by username
- Search posts by hashtags and location
- Explore feed with personalized recommendations

## 5. Messaging & Interaction
- Direct messaging (1-1 and group chats)
- Push notifications for likes, comments, follows, messages, and mentions

## 6. Live & Media Handling
- Support for live streaming
- Media compression and CDN delivery for optimized performance

## 7. Additional Features
- Content moderation: report posts, block users
- Caching for limited offline support (view old feed, retry uploads)

##
# Non-Functional Requirements (NFR) for Instagram-like Mobile App

## 1. Performance & Offline Support
- App should launch within 1–2 seconds.
- Smooth scrolling and UI interactions (60fps).
- Cache recent feed posts for offline viewing.
- Retry failed uploads automatically when the network is back.

## 2. Battery & Network Efficiency
- Optimize background tasks (uploads, location) to reduce battery usage.
- Use media compression and CDN for fast and efficient content delivery.

## 3. Scalability & Availability
- Support millions of users and posts with 99.9% uptime.
- Backend should scale horizontally to handle traffic spikes.

## 4. Security & Privacy
- Secure authentication (OAuth 2.0 / JWT).
- Use HTTPS for all network communication.
- Basic privacy controls (private/public accounts).

## 5. Reliability
- Graceful degradation when backend or network is slow.
- Crash reporting and basic error monitoring.

## 6. User Experience
- Consistent and responsive UI across devices.
- Support for multiple languages (if needed).
- Basic accessibility (e.g., dynamic font sizing).


