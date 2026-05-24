# Sub-Agent Plan

Yes — this project can be split across sub-agents using clear ownership boundaries.

## Available Sub-Agent Strategy

Sub-agents can work well for:
- research
- code review
- separate feature streams
- debugging different areas

Sub-agents are less suitable for:
- tasks needing live user input
- tightly coupled file edits without coordination
- anything needing persistent background life

## Proposed Split for সহজ বাজার খাতা

### Agent A — Foundation
Owns:
- theme
- router
- app shell
- database
- shared widgets

### Agent B — Auth
Owns:
- login
- current user
- auth guard
- logout flow

### Agent C — Wallet + Balance
Owns:
- wallet screens
- balance calculation
- wallet detail
- assistant ledger

### Agent D — Bazar Core
Owns:
- bazar list
- bazar detail
- item states
- item edit sheet
- bazar summary

### Agent E — Money + Reports
Owns:
- money entry
- direct expense
- reports
- monthly close

### Agent F — Admin + Search + Settings + Sync UI
Owns:
- admin
- add user
- notifications
- search
- settings
- offline queue
- more/profile

## Important Constraints
- Sub-agents do not know chat context unless it is explicitly passed.
- Sub-agent results are self-reported and must be verified.
- File collisions are possible, so ownership boundaries must stay strict.
- Shared files should be edited by one owner at a time.

## Recommendation
Use sub-agents only after the foundation is scaffolded, so feature agents can work in parallel with less overlap.
