---
title: Realtime Complete Guide
type: note
permalink: guides/realtime/realtime-guide
tags:
- realtime
- websockets
- subscriptions
- presence
- broadcast
- postgres-changes
- implementation
- consolidated
---

# Realtime Complete Guide

Comprehensive guide to Supabase Realtime features including Postgres Changes, Presence, Broadcast, with configuration, patterns, and implementation details.

## Overview

[overview] Supabase Realtime provides real-time data synchronization via WebSockets #realtime #websockets
[feature] Three main features: Postgres Changes, Presence, Broadcast #realtime #capabilities
[feature] Postgres Changes listen to INSERT, UPDATE, DELETE events on database tables #realtime #database
[feature] Presence tracks which users are online and shares state between them #realtime #users
[feature] Broadcast sends ephemeral messages between clients without database persistence #realtime #messaging
[architecture] All communication over WebSockets for low-latency bidirectional updates #realtime #performance

## Implementation Status

[status] Realtime fully implemented and production-ready #implementation #complete
[tables] profiles table enabled for realtime with REPLICA IDENTITY FULL #database #config
[tables] posts table enabled for realtime with REPLICA IDENTITY FULL #database #config
[migration] Migration 20251005052959_enable_realtime.sql configures realtime #database #migration
[examples] 8 working examples (7 Node.js + 1 browser) in examples/realtime/ #testing #demos
[documentation] 2,336+ lines of code and documentation added #documentation #comprehensive

## Quick Start

[quickstart] Install @supabase/supabase-js client library #setup #npm
[quickstart] Create Supabase client with URL and anon key #setup #client
[quickstart] Create channel with unique name #setup #channel
[quickstart] Subscribe to events with .on() method #setup #subscribe
[quickstart] Call .subscribe() to establish connection #setup #connect
[quickstart] Clean up with supabase.removeChannel() when done #setup #cleanup

### Basic Subscription Example

[example] Create channel: `supabase.channel('my-channel')` #code #basic
[example] Listen to changes: `.on('postgres_changes', {event, schema, table}, handler)` #code #postgres
[example] Subscribe: `.subscribe()` #code #connect
[example] Cleanup: `await supabase.removeChannel(channel)` #code #cleanup

## Feature 1: Postgres Changes

[postgres] Listen to database events in real-time #feature #database
[event] INSERT event when new rows added #postgres #event
[event] UPDATE event when rows modified #postgres #event
[event] DELETE event when rows removed #postgres #event
[event] Wildcard * event listens to all changes #postgres #event

### Event Payload Structure

[payload] schema: Database schema name #postgres #data
[payload] table: Table name #postgres #data
[payload] commit_timestamp: When change committed #postgres #data
[payload] eventType: INSERT, UPDATE, or DELETE #postgres #data
[payload] new: New row data for INSERT and UPDATE #postgres #data
[payload] old: Old row data for UPDATE and DELETE #postgres #data
[payload] errors: Array of error messages if any #postgres #data

### Database Configuration

[config] Add table to publication: `ALTER PUBLICATION supabase_realtime ADD TABLE table_name` #database #sql
[config] Set replica identity: `ALTER TABLE table_name REPLICA IDENTITY FULL` #database #sql
[requirement] REPLICA IDENTITY FULL required for UPDATE/DELETE events #database #constraint
[requirement] RLS SELECT permission required to receive updates #database #security

### Server-Side Filtering

[filter] Use filter parameter to reduce data sent to client #optimization #security
[filter] Format: `filter: 'column=eq.value'` for equality checks #syntax #filtering
[example] Filter published posts: `filter: 'published=eq.true'` #code #filtering
[benefit] Filters reduce bandwidth and improve security #optimization #security

## Feature 2: Presence

[presence] Track which users are online and share state #feature #users
[presence] Sync event triggered when presence state changes #event #sync
[presence] Join event when new users connect #event #join
[presence] Leave event when users disconnect #event #leave
[method] channel.track() to broadcast user's presence #api #presence
[method] channel.presenceState() to get all online users #api #presence

### Presence Events

[event-sync] Sync event provides complete presence state #presence #sync
[event-join] Join event includes newPresences array #presence #join
[event-leave] Leave event includes leftPresences array #presence #leave
[usecase] Perfect for "who's online" features #presence #application

## Feature 3: Broadcast

[broadcast] Send ephemeral messages between clients #feature #messaging
[broadcast] Messages not persisted to database #feature #ephemeral
[broadcast] Low-latency communication for real-time interactions #feature #performance
[method] channel.send() to broadcast messages #api #broadcast
[method] .on('broadcast', {event}, handler) to listen #api #broadcast
[usecase] Perfect for chat, typing indicators, cursor positions #broadcast #application

## Configuration Files

### Config.toml Settings

[config-file] supabase/config.toml contains realtime rate limits #configuration #file
[limit] max_connections: 100 concurrent connections per client IP #rate-limit #connections
[limit] max_channels_per_client: 100 channels per connection #rate-limit #channels
[limit] max_joins_per_second: 500 channel joins per second per client #rate-limit #joins
[limit] max_messages_per_second: 1000 messages per second per client #rate-limit #messages
[limit] max_events_per_second: 100 database events per second per channel #rate-limit #events

### Migration Details

[migration-file] 20251005052959_enable_realtime.sql enables realtime #database #file
[migration-action] Adds profiles to supabase_realtime publication #database #profiles
[migration-action] Adds posts to supabase_realtime publication #database #posts
[migration-action] Sets REPLICA IDENTITY FULL on profiles #database #profiles
[migration-action] Sets REPLICA IDENTITY FULL on posts #database #posts
[migration-action] Updates table comments with realtime status #database #documentation

## Common Patterns

### Pattern 1: Live Feed

[pattern] Display new content as it's created in real-time #pattern #feed
[usecase] News feeds, activity streams, social media #pattern #application
[implementation] Subscribe to INSERT events on posts table #pattern #code
[implementation] Filter for published=true to show only public posts #pattern #filtering
[implementation] Add new posts to top of feed in handler #pattern #ui

### Pattern 2: Live Editing

[pattern] Show when others are editing a document #pattern #collaboration
[usecase] Collaborative editors, shared documents, real-time forms #pattern #application
[implementation] Use Presence to track active editors #pattern #presence
[implementation] Use Broadcast for cursor positions and selections #pattern #broadcast
[implementation] Show editor list and cursor overlays in UI #pattern #ui

### Pattern 3: User-Specific Updates

[pattern] Listen only to changes relevant to current user #pattern #filtering
[usecase] Notifications, personal messages, user-specific data #pattern #application
[implementation] Filter events with `filter: 'user_id=eq.${userId}'` #pattern #filtering
[implementation] Use auth.uid() to get current user ID #pattern #auth
[implementation] Show notifications or updates specific to user #pattern #ui

### Pattern 4: Chat Application

[pattern] Real-time chat with presence and messaging #pattern #chat
[usecase] Team chat, messaging apps, live support #pattern #application
[implementation] Use Presence to show online users #pattern #presence
[implementation] Use Broadcast for messages and typing indicators #pattern #broadcast
[implementation] Track user presence with avatar and status #pattern #state
[implementation] Send messages with timestamp and user info #pattern #data

### Pattern 5: Live Dashboard

[pattern] Display real-time metrics and updates #pattern #monitoring
[usecase] Analytics dashboards, monitoring systems, admin panels #pattern #application
[implementation] Subscribe to multiple tables with separate channels #pattern #multiple
[implementation] Update dashboard widgets on each event #pattern #ui
[implementation] Show real-time counters and graphs #pattern #visualization

## Security

### RLS Integration

[security] Realtime respects Row Level Security policies #security #rls
[security] Users only receive updates for rows they can SELECT #security #access
[security] RLS policies enforced at database level #security #enforcement
[requirement] User must have SELECT permission on table #security #requirement
[example] Policy: `CREATE POLICY "name" ON table FOR SELECT USING (auth.uid() = user_id)` #security #sql

### Authentication

[auth] Use authenticated clients for sensitive data #security #authentication
[auth] Set JWT token in client headers #security #jwt
[auth] Supabase client automatically includes auth token #security #automatic
[method] Set headers: `{Authorization: 'Bearer ${userJwt}'}` #security #headers

### Server-Side Filtering

[security-practice] Filter on server to reduce data exposure #security #optimization
[security-practice] Avoid receiving all data then filtering client-side #security #antipattern
[benefit] Server-side filtering reduces bandwidth #security #performance
[benefit] Server-side filtering prevents data leaks #security #privacy

## Rate Limiting

### Default Limits

[limit-default] 100 concurrent connections per client IP #rate-limit #connection
[limit-default] 100 channels per connection #rate-limit #channel
[limit-default] 500 joins per second per client #rate-limit #join
[limit-default] 1000 messages per second per client #rate-limit #message
[limit-default] 100 events per second per channel #rate-limit #event

### Handling Rate Limits

[strategy] Share channels: Use one channel for multiple subscriptions #rate-limit #optimization
[strategy] Debounce updates: Limit event processing frequency #rate-limit #debounce
[strategy] Connection pooling: Reuse connections across components #rate-limit #pooling
[strategy] Implement backoff: Exponential backoff on reconnection #rate-limit #retry
[technique] Debouncing delays handler execution until events stop #rate-limit #technique

## Best Practices

### 1. Always Clean Up Subscriptions

[practice] Remove channels when component unmounts #best-practice #cleanup
[practice] React: Use useEffect return function for cleanup #best-practice #react
[practice] Call supabase.removeChannel(channel) to disconnect #best-practice #api
[reason] Prevents memory leaks and connection exhaustion #best-practice #performance

### 2. Use Unique Channel Names

[practice] Include unique identifiers in channel names #best-practice #naming
[practice] Good: `supabase.channel('post:${postId}')` #best-practice #example
[practice] Avoid: `supabase.channel('post')` - too generic #best-practice #antipattern
[reason] Prevents cross-talk between different data contexts #best-practice #isolation

### 3. Handle Reconnections

[practice] Listen to system events: connected, disconnected, reconnecting #best-practice #events
[practice] Update UI to show connection status #best-practice #ux
[practice] Implement reconnection logic if needed #best-practice #reliability
[reason] Provides better user experience during network issues #best-practice #ux

### 4. Batch Operations

[practice] Use one channel with multiple .on() handlers #best-practice #optimization
[practice] Avoid creating multiple channels for same data #best-practice #antipattern
[reason] Reduces connection overhead #best-practice #performance
[reason] Stays within rate limits #best-practice #limits

### 5. Test Thoroughly

[testing] Test with multiple clients simultaneously #best-practice #testing
[testing] Test under load with many events #best-practice #testing
[testing] Test disconnection and reconnection scenarios #best-practice #testing
[testing] Test with RLS policies enabled #best-practice #testing
[testing] Test rate limiting behavior #best-practice #testing

### 6. Monitor Performance

[monitoring] Track active connection count #best-practice #metrics
[monitoring] Monitor message throughput #best-practice #metrics
[monitoring] Watch for dropped events #best-practice #metrics
[monitoring] Check client-side memory usage #best-practice #metrics

## Testing

### Automated Test Suite

[test-file] examples/realtime/test-realtime.js - comprehensive test suite #testing #automation
[test-coverage] Creates test post (INSERT event) #testing #insert
[test-coverage] Updates test post (UPDATE event) #testing #update
[test-coverage] Deletes test post (DELETE event) #testing #delete
[test-coverage] Verifies all events received correctly #testing #validation
[test-run] Run with `npm run test:realtime` from project root #testing #command

### Manual Testing Examples

[examples] 7 Node.js examples for different features #testing #examples
[example-basic] basic-subscription.js - simple channel subscription #testing #basic
[example-table] table-changes.js - event-specific handlers #testing #events
[example-filter] filtered-subscription.js - server-side filtering #testing #filtering
[example-presence] presence.js - online user tracking #testing #presence
[example-broadcast] broadcast.js - ephemeral messaging #testing #broadcast
[example-browser] rate-limiting.html - browser demo with visualization #testing #browser

### Running Examples

[run-examples] `cd examples/realtime && npm install` #testing #setup
[run-examples] `npm run basic` - basic subscription #testing #command
[run-examples] `npm run table-changes` - table-specific changes #testing #command
[run-examples] `npm run filtered` - filtered subscriptions #testing #command
[run-examples] `npm run presence` - presence tracking #testing #command
[run-examples] `npm run broadcast` - broadcast messages #testing #command
[run-examples] `npm run test` - automated test suite #testing #command

## Troubleshooting

### Not Receiving Updates

[troubleshoot] Check table in publication: `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime'` #troubleshooting #sql
[troubleshoot] Check RLS policies: `SELECT * FROM pg_policies WHERE tablename = 'your_table'` #troubleshooting #sql
[troubleshoot] Check replica identity: `SELECT relname, relreplident FROM pg_class WHERE relname = 'your_table'` #troubleshooting #sql
[troubleshoot] Check subscription status in callback #troubleshooting #debugging
[expected] Replica identity should be 'f' for FULL #troubleshooting #validation

### Connection Issues

[issue] Verify API keys are correct #troubleshooting #config
[issue] Check network connectivity #troubleshooting #network
[issue] Review browser console for errors #troubleshooting #debugging
[issue] Check CORS settings if cross-origin #troubleshooting #cors
[issue] Verify WebSocket support in browser/environment #troubleshooting #compatibility

### Performance Issues

[issue] Reduce number of active subscriptions #troubleshooting #optimization
[issue] Use filters to limit data sent #troubleshooting #filtering
[issue] Implement client-side debouncing #troubleshooting #debounce
[issue] Check rate limit settings in config.toml #troubleshooting #config
[issue] Monitor network bandwidth usage #troubleshooting #monitoring

## Adding Realtime to New Tables

[checklist] Add to publication: `ALTER PUBLICATION supabase_realtime ADD TABLE your_table` #workflow #sql
[checklist] Set replica identity: `ALTER TABLE your_table REPLICA IDENTITY FULL` #workflow #sql
[checklist] Update RLS policies to allow SELECT #workflow #security
[checklist] Test subscription with example code #workflow #testing
[checklist] Document expected events #workflow #documentation
[checklist] Update client code to handle events #workflow #implementation
[checklist] Test rate limits under load #workflow #testing
[checklist] Update project documentation #workflow #documentation

## Documentation Files

[doc] REALTIME.md - 593 lines comprehensive guide #documentation #complete
[doc] examples/realtime/QUICKSTART.md - 5-minute getting started #documentation #quickstart
[doc] examples/realtime/README.md - Complete examples guide #documentation #examples
[doc] README.md Realtime section - Project-level overview #documentation #project
[doc] DEVOPS.md Realtime section - DevOps configuration guide #documentation #devops

## Examples Location

[location] examples/realtime/ directory contains all examples #examples #structure
[files] 10 files with 1,398 lines of example code #examples #volume
[package] package.json with npm scripts for easy execution #examples #scripts
[browser] rate-limiting.html - interactive browser demo #examples #browser
[testing] test-realtime.js - automated test suite #examples #testing

## Implementation Impact

[impact] 16 files created or modified #implementation #metrics
[impact] 2,336+ lines of code and documentation added #implementation #metrics
[impact] 8 working examples covering all features #implementation #metrics
[impact] 4 comprehensive documentation guides #implementation #metrics
[impact] 3 realtime features fully documented #implementation #metrics
[impact] 5 common patterns with complete implementations #implementation #metrics

## Learning Path

[learning-1] Start with examples/realtime/QUICKSTART.md for 5-minute intro #learning #quickstart
[learning-2] Try examples in examples/realtime/*.js directory #learning #examples
[learning-3] Read docs/REALTIME.md for deep dive #learning #comprehensive
[learning-4] Build your feature using documented patterns #learning #implementation

## Production Readiness

[production] Complete realtime functionality for profiles and posts tables #production #complete
[production] Production-ready configuration with appropriate rate limits #production #config
[production] Comprehensive examples covering all 3 realtime features #production #examples
[production] Detailed documentation with 5 common patterns #production #docs
[production] Automated testing with diagnostic output #production #testing
[production] Security best practices and RLS integration #production #security
[production] Performance guidance and optimization strategies #production #performance

## Related Documentation

- [[Testing Guide]] - Realtime testing procedures
- [[RLS Policy Guide]] - Security integration
- [[Storage Configuration Guide]] - Storage realtime features
- [[Development Workflows]] - Development procedures
- [[Contributing Guide]] - Development guidelines

## Source Files Consolidated

This guide consolidates information from:
- REALTIME.md (594 lines) - Comprehensive guide with features, patterns, security
- REALTIME_IMPLEMENTATION.md (410 lines) - Implementation summary, examples, testing

All source files have been merged into this comprehensive semantic guide.
