# Growfolio iOS API + WebSocket Implementation Manual

## Scope
This manual describes how an iOS client should authenticate, call the HTTP API, and integrate the real-time WebSocket interface. It is based on the current server implementation in this repo.

---

## 1) Authentication & JWT (Apple Sign In)

### Source of truth
- The server only accepts Apple Sign In identity tokens (JWTs).
- The JWT `sub` claim is treated as the user ID.
- The JWT `exp` claim is used for expiration handling.

### iOS steps
1. Use Sign in with Apple (`ASAuthorizationAppleIDProvider`) to obtain `identityToken`.
2. First sign-in only: capture `fullName` and pass it to the backend (Apple only provides it once).

### HTTP auth
- All protected HTTP endpoints require:
  - `Authorization: Bearer <identity_token>`

### Token exchange endpoint
Use this for initial user creation and metadata:
```
POST /api/v1/auth/token
{
  "identity_token": "<apple_jwt>",
  "user_first_name": "Optional - first sign-in only",
  "user_last_name": "Optional - first sign-in only"
}
```
Response includes `user_id`, `email`, `name`, `alpaca_account_status`.

---

## 2) WebSocket Endpoint

### URL
```
wss://api.growfolio.app/api/v1/ws?token=<apple_jwt>&device_type=ios&app_version=1.2.3
```

### Query parameters
- `token` (required): Apple identity token (JWT).
- `device_type` (optional): `ios`, `android`, `web`.
- `app_version` (optional): client version string.

### Auth behavior
- Invalid token: connection closed with code `4001`.
- Token expired during session: connection closed with code `4002`.

---

## 3) Message Format (JSON Text Frames)

### Server -> Client
```json
{
  "id": "uuid",
  "type": "event|system|ack|error",
  "event": "event_name_or_null",
  "timestamp": "2024-01-01T12:00:00.000000",
  "data": { ... }
}
```

### Client -> Server
```json
{
  "type": "subscribe|unsubscribe|pong|refresh_token",
  "channels": ["quotes", "fx"],
  "symbols": ["AAPL", "MSFT"],
  "token": "new_apple_jwt"
}
```

### Important parsing notes
- Numbers may be serialized as strings (e.g., decimals). Parse using `Decimal`/`NSDecimalNumber` when precision matters.
- `timestamp` is UTC `isoformat()` with no timezone suffix; treat as UTC.
- Ignore unknown fields for forward compatibility.

---

## 4) Connection Lifecycle

### Welcome message (system)
Sent immediately after connect:
```json
{
  "type": "system",
  "data": {
    "connection_id": "<uuid>",
    "subscriptions": ["orders", "positions", "account", "dca", "transfers"],
    "heartbeat_interval": 30
  }
}
```

### Default subscriptions
Automatically subscribed on connect:
- `orders`, `positions`, `account`, `dca`, `transfers`

---

## 5) Heartbeats

- Server sends `system` heartbeat every 30s:
```json
{ "type": "system", "event": "heartbeat", "data": { "ping": true } }
```

- Client must respond:
```json
{ "type": "pong" }
```

- If no pong within ~40s (30s interval + 10s timeout), server closes the socket.

---

## 6) Token Expiry & Refresh

### Server warning
When token expires soon (<= 60s):
```json
{
  "type": "event",
  "event": "token_expiring",
  "data": {
    "expires_in_seconds": 45,
    "expires_at": "2024-01-01T12:00:45.000000"
  }
}
```

### Client refresh
1. Acquire a new Apple identity token via Sign in with Apple.
2. Send:
```json
{ "type": "refresh_token", "token": "<new_apple_jwt>" }
```

### Success response
```json
{
  "type": "event",
  "event": "token_refreshed",
  "data": { "expires_at": "2024-01-01T13:00:00.000000" }
}
```

### Failure response
```json
{
  "type": "error",
  "data": { "error": "Token refresh failed: <reason>" }
}
```

---

## 7) Channel Subscriptions

### Available channels
`orders`, `positions`, `account`, `dca`, `transfers`, `fx`, `quotes`, `baskets`

### Subscribe
```json
{
  "type": "subscribe",
  "channels": ["quotes"],
  "symbols": ["AAPL", "MSFT"]
}
```

### Unsubscribe
```json
{
  "type": "unsubscribe",
  "channels": ["quotes"],
  "symbols": ["AAPL"]
}
```

### Ack response
```json
{
  "type": "ack",
  "data": { "action": "subscribed", "channels": ["quotes"] }
}
```

Quotes require both the `quotes` channel and a `symbols` list. Use uppercase symbols.

---

## 8) Close Codes

Application-specific close codes:
- `4001` Unauthorized (invalid/missing token)
- `4002` Token expired
- `4003` User not found
- `4004` Account inactive
- `4005` Rate limited (max connections per replica)
- `4006` Server shutdown

Recommended actions:
- `4001/4002`: re-auth, refresh token, reconnect.
- `4005`: exponential backoff, retry later.
- `4006`: reconnect with backoff.

---

## 9) Events (Exhaustive)

### Defined event types
Orders:
- `order_created`, `order_status`, `order_fill`, `order_cancelled`

Positions:
- `position_created`, `position_updated`, `position_closed`

Account:
- `cash_changed`, `buying_power_changed`, `account_status_changed`

DCA:
- `dca_executed`, `dca_failed`, `dca_status_changed`

Transfers:
- `transfer_complete`, `transfer_failed`

FX:
- `fx_rate_updated`

Quotes:
- `quote_updated`

Baskets:
- `basket_value_changed`

System:
- `token_expiring`, `token_refreshed`, `server_shutdown`, `heartbeat`

### Currently emitted by server
- Orders: `order_created`, `order_status`, `order_fill`, `order_cancelled`
- Account: `account_status_changed`
- Transfers: `transfer_complete`, `transfer_failed`
- Quotes: `quote_updated`
- System: `token_expiring`, `token_refreshed`, `server_shutdown`, `heartbeat`

Other events are defined for forward compatibility but not yet emitted.

---

## 10) Event Payloads

### Order events
From Alpaca trade updates:
```json
{
  "order_id": "alpaca_order_id",
  "client_order_id": "optional",
  "symbol": "AAPL",
  "side": "buy|sell",
  "filled_qty": "10.5",
  "filled_price": "150.25",
  "status": "filled|new|canceled|...",
  "event": "fill|partial_fill|new|canceled|...",
  "basket_id": "optional",
  "dca_schedule_id": "optional"
}
```

### Account status change
```json
{
  "status": "ACTIVE|... ",
  "account_id": "alpaca_account_id"
}
```

### Transfer events
```json
{
  "transfer_id": "id",
  "direction": "INCOMING|OUTGOING",
  "amount": "100.00",
  "currency": "USD",
  "status": "COMPLETE|FAILED|..."
}
```

### Quote updates
```json
{
  "symbol": "AAPL",
  "price_usd": "170.12",
  "price_gbp": "135.22",
  "bid": "170.10",
  "ask": "170.14",
  "change_percent": "0.58",
  "fx_rate": "1.2567",
  "timestamp": "2024-01-01T12:00:00.000000"
}
```

### Token expiring
```json
{
  "expires_in_seconds": 60,
  "expires_at": "2024-01-01T12:01:00.000000"
}
```

### Token refreshed
```json
{ "expires_at": "2024-01-01T13:00:00.000000" }
```

### Server shutdown (system)
```json
{ "message": "Server is shutting down" }
```

---

## 11) iOS Implementation Notes

### WebSocket
- Use `URLSessionWebSocketTask`.
- Send/receive text frames with JSON.

### JSON decoding
- Use `ISO8601DateFormatter` (UTC) for timestamps.
- Use `NSDecimalNumber` or `Decimal` for numeric strings.

### Suggested reconnect strategy
- On error/close: exponential backoff with jitter.
- Refresh token before reconnect if last close code was `4001/4002`.

### Backgrounding
- If the app goes to background, expect WebSocket to disconnect.
- Reconnect and re-subscribe when the app returns to foreground.

---

## 12) Minimal Flow Example

1. Apple Sign In -> identity token.
2. `POST /api/v1/auth/token` (first sign-in only: include name).
3. Open WebSocket with `token` in query.
4. On welcome: store `connection_id`, note `heartbeat_interval`.
5. Send `subscribe` for `quotes` + symbols as needed.
6. Respond to `heartbeat` with `pong`.
7. On `token_expiring`: refresh Apple token, send `refresh_token`.
8. Handle events and update UI in real time.
