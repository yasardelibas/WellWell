# MedGuard

A safety layer between the medication label and the person taking it.

MedGuard scans medication labels, identifies active ingredients against trusted drug data,
detects duplicate active ingredients across the medications a person already takes, and keeps
reminders and adherence history. It is not a diagnostic tool and never changes medication
instructions.

## Product principle

> AI extracts and explains. Trusted data verifies. The user decides.

The large language model sits outside the decision path:

```
Camera → OCR/vision extraction → normalisation → trusted drug database lookup
       → user confirmation → deterministic safety engine → structured finding
       → UI (always) and AI explanation (optional)
```

The safety engine never calls a model, and a model can never create a finding. When the AI
explanation service is disabled or unreachable, a deterministic template produces the same
explanation and every safety feature keeps working.

## Repository layout

```
backend/          .NET 8 minimal API, vertical slices over clean architecture
  src/MedGuard.Domain          entities, enums, domain rules
  src/MedGuard.Contracts       request/response DTOs shared with the client
  src/MedGuard.Application     safety engine, normaliser, label parser, AI guardrails
  src/MedGuard.Infrastructure  EF Core, PostgreSQL, drug data providers, auth, audit
  src/MedGuard.Api             endpoints, validation, rate limiting, telemetry, seeding
  tests/                       unit and integration tests
mobile_flutter/   Flutter iOS/Android client — same design, APIs and copy
  lib/                        screens, API client, theme
  assets/illustrations        onboarding and empty-state art
docker-compose.yml             PostgreSQL and Redis for local development
```

## Running locally

### 1. Infrastructure

```bash
docker compose up -d postgres
```

Redis is optional. Without it the API falls back to an in-memory distributed cache.

```bash
docker compose up -d redis
```

### 2. Backend

```bash
cd backend
dotnet run --project src/MedGuard.Api --launch-profile http
```

The API listens on `http://localhost:5175`, applies migrations on start, and seeds the demo
account. Swagger is available at `/swagger` in development.

### 3. Mobile (Flutter)

USB ile fiziksel iPhone/Android’de çalışır; Expo Go veya tünel gerekmez.

```bash
cd mobile_flutter
flutter pub get
flutter run
```

API adresi varsayılan olarak `https://164-90-169-182.sslip.io`. Yerel backend için:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.39:5175
```

## Demo account

| Field    | Value                 |
| -------- | --------------------- |
| Email    | `demo@medguard.app`   |
| Password | `DemoPass123!`        |

The sign-in screen has a one-tap demo button, which calls `POST /api/demo/login`.

The demo account starts with Tylenol Extra Strength (acetaminophen), Zyrtec (cetirizine) and
Glucophage (metformin), plus confirmed reminder schedules.

### Demo story

1. Open the app; today's doses are on the dashboard.
2. Tap **Scan**. Without a vision key configured, use **Enter manually** and the sample label
   button, which fills in a Parol label.
3. MedGuard extracts the brand, ingredient and directions with per-field confidence, then
   matches candidates against the drug data provider.
4. Confirm the medication. Parol normalises to acetaminophen.
5. The safety engine detects the duplicate active ingredient shared with Tylenol Extra
   Strength and shows a warning.
6. Tap **Why am I seeing this?** for the ingredient-level explanation, the data source and the
   verification status.
7. Create reminders from the label directions; the suggested times must be confirmed.
8. Open the **Emergency card** to show the revocable QR code.

## Safety and privacy behaviour

- A medication scanned by OCR is never saved without user confirmation.
- A medication is marked `unverified` when the trusted lookup does not match, and provider
  failure never becomes a successful safety result.
- No screen claims that medications are safe together. The clear state reads "No issues were
  detected by the checks currently available in MedGuard".
- Drug interaction checking reports `not_configured` unless a real provider is wired in. No
  interactions are fabricated.
- Severity is never expressed with colour alone; each state carries an icon and a label.
- Notifications can be switched to privacy mode so the lock screen omits medication names.
- The emergency card shares only the fields the owner enables, behind an opaque revocable
  token. Regenerating the QR invalidates the previous link immediately.
- Caregiver access is two-step: the caregiver accepts the invitation, then the owner approves
  the exact permission set. Accepting alone grants nothing, and revocation is immediate.
- Access tokens are short-lived with refresh rotation, tokens live in the platform secure
  store, and the app supports a biometric lock, screenshot protection and an app-switcher
  privacy shield.

## Configuration

Key settings in `backend/src/MedGuard.Api/appsettings.json`:

| Section              | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `ConnectionStrings`  | PostgreSQL, and Redis when caching is enabled                         |
| `Jwt`                | Issuer, audience, signing key, token lifetimes                        |
| `Security`           | Field encryption key for emergency card and medication notes          |
| `DrugData`           | Enabled providers (`local`, `rxnorm`, `openfda`) and interaction provider |
| `Ai`                 | Explanation and vision toggles, model names, API key                  |
| `Scanning`           | Image retention, size limit, manual review threshold                  |
| `Demo`               | Demo account toggle and credentials                                   |

Signing and encryption keys are generated for development when left blank. Supply real values
through environment variables or a secret store in any other environment.

### Enabling the AI layer

Both AI features are off by default and the app is fully functional without them: safety
findings come from the deterministic engine, explanations fall back to a template, and the
scanner falls back to text extraction. To switch them on locally, keep the key out of the
repository by using user secrets:

```bash
cd backend/src/MedGuard.Api
dotnet user-secrets set "Ai:ApiKey" "sk-..."
dotnet user-secrets set "Ai:ExplanationsEnabled" "true"
dotnet user-secrets set "Ai:VisionEnabled" "true"
```

`Ai:VisionEnabled` lets the scanner read a captured photo directly; `Ai:ExplanationsEnabled`
rewrites an existing finding in plain language. Generated explanations still pass through an
output guard that rejects any text drifting into clinical advice, and a rejected response
falls back to the deterministic template.

## Tests

```bash
cd backend
dotnet test
```

Unit tests cover the safety engine's required scenarios: the same ingredient in two products,
different spellings that normalise to the same ingredient, distinct ingredients, unverified
medications, empty ingredient lists and provider failure. Integration tests cover scan to
confirmation, safety analysis, schedule to dose event, the caregiver permission lifecycle and
QR token to emergency card.
