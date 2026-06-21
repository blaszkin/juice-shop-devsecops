# Naprawione podatności (Shift-Left Security)

Dokument zestawia podatności naprawione w ramach projektu — po **2–4 znaleziska
High/Critical w każdej kategorii skanu**, ze stanem przed/po. Wszystkie naprawy są
weryfikowalne w kolejnych przebiegach pipeline'u (artefakty SCA/SAST/Secrets/DAST/Trivy).

## SCA — `npm audit` (zależności)

Zastosowano `overrides` w `package.json`, wymuszające załatane wersje podatnych zależności
przechodnich (bez psucia działania aplikacji).

| Pakiet | Było | Jest | Podatność |
|--------|------|------|-----------|
| `crypto-js` | < 4.2.0 | ^4.2.0 | **CRITICAL** — PBKDF2 ~1,3 mln× słabszy od standardu |
| `http-cache-semantics` | < 4.1.1 | ^4.1.1 | HIGH — ReDoS (HTTP request) |
| `moment` | podatne | ^2.30.1 | HIGH — ReDoS / path traversal |

**Wynik (root):** High **25 → 21**, Critical **5 → 3** (naprawione: 1 Critical + 2 High; pozostałe to celowe podatności Juice Shop bez dostępnej łatki).

## SAST — Semgrep (kod źródłowy)

| Plik | Podatność | Naprawa |
|------|-----------|---------|
| `routes/login.ts:34` | **SQL Injection** (interpolacja stringa w zapytaniu logowania) | zapytanie sparametryzowane (named replacements) |
| `routes/search.ts:23` | **SQL Injection** (interpolacja w klauzuli `LIKE`) | zapytanie sparametryzowane (named replacements) |

Reguła `express-sequelize-injection` (severity ERROR/High). Liczba znalezisk ERROR: **7 → 5**.

## Secrets Scan — Gitleaks

| Lokalizacja | Sekret | Naprawa |
|-------------|--------|---------|
| `lib/insecurity.ts:23` | **klucz prywatny RSA** (reguła `private-key`) | przeniesiony do `process.env.JWT_PRIVATE_KEY` (sekret w vaulcie GitHub Actions, wstrzykiwany przy deployu) |
| `lib/insecurity.ts:44` | sekret HMAC (`generic-api-key`) | przeniesiony do `process.env.HMAC_SECRET` |
| `ctf.key` | plik z kluczem CTF | usunięty z repozytorium + dodany do `.gitignore` |

Najpoważniejsze (jedyne) znalezisko `private-key` zostało wyeliminowane. Sekrety
dostarczane są wyłącznie przez menedżer sekretów CI (`${{ secrets.* }}`), nie z kodu.

## DAST — OWASP ZAP (działająca aplikacja)

W `server.ts` dodano brakujące nagłówki bezpieczeństwa wykrywane przez ZAP:

| Nagłówek | Alert ZAP | Naprawa |
|----------|-----------|---------|
| `Content-Security-Policy` | *CSP: Header Not Set* | `helmet.contentSecurityPolicy(...)` |
| `Strict-Transport-Security` | *HSTS Header Not Set* | `helmet.hsts(...)` |
| `Referrer-Policy` | *Referrer-Policy Header Not Set* | `helmet.referrerPolicy(...)` |

## Trivy — skan obrazu kontenera

Skan obrazu (HIGH,CRITICAL) wykonywany jest **przed** publikacją do rejestru. Liczba
podatnych zależności w obrazie spada dzięki `overrides` z etapu SCA (m.in. `crypto-js`
CRITICAL → załatany), ponieważ obraz budowany jest z tego samego `package.json`.

## Obraz kontenera

Po pomyślnym skanie obraz publikowany jest do publicznego rejestru:
`ghcr.io/blaszkin/juice-shop-devsecops:latest`.
