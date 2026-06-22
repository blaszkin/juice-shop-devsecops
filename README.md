# Mini-projekt DevSecOps — OWASP Juice Shop

Projekt na potrzeby przedmiotu **Ochrona Systemów Operacyjnych** (Laboratorium 13–14,
*Shift-Left Security / DevSecOps*). Pokazuje, jak zintegrować testy bezpieczeństwa z
pipeline'em CI/CD dla celowo podatnej aplikacji webowej **OWASP Juice Shop**.

Autor: **Błażej Sułtanowski**, nr indeksu **283821**.

## Pipeline CI/CD (GitHub Actions)

Plik: [`.github/workflows/devsecops.yml`](.github/workflows/devsecops.yml)

| Etap | Zadanie | Narzędzie |
|------|---------|-----------|
| 1 | Budowanie obrazu Docker | `docker build` (multi-stage → distroless) |
| 2a | **SCA** — skan zależności | `npm audit` |
| 2b | **SAST** — analiza kodu | **Semgrep** (OWASP Top Ten, JS/TS, secrets) |
| 2c | **Secrets Scan** | **Gitleaks** |
| 2d | **DAST** — skan działającej aplikacji | **OWASP ZAP** (baseline) na tymczasowym deploymencie w CI |
| 3 | Skan obrazu przed publikacją | **Trivy** (HIGH, CRITICAL) |
| 4 | Push obrazu do rejestru | **ghcr.io** (token wbudowany) |

Skany 2a–2c analizują kod źródłowy i zależności równolegle. Obraz budowany jest raz i
współdzielony (artefakt) między etapami Trivy, DAST i push. DAST uruchamia aplikację jako
tymczasowy kontener w sieci Dockera i skanuje ją dynamicznie (OWASP ZAP), zgodnie z ideą
*temporary deployment in CI*.

## Naprawione podatności (Shift-Left)

W ramach projektu naprawiono po **2–3 podatności High/Critical** w każdej kategorii skanu —
szczegóły (stan przed/po) opisano w pliku [`SECURITY_FIXES.md`](SECURITY_FIXES.md) oraz w
sprawozdaniu.

## Obraz kontenera

Opublikowany obraz: `ghcr.io/blaszkin/juice-shop-devsecops:latest`

## Weryfikacja

- Repozytorium: <https://github.com/blaszkin/juice-shop-devsecops>
- Przebiegi CI/CD (GitHub Actions): <https://github.com/blaszkin/juice-shop-devsecops/actions>
- Publiczny obraz (ghcr.io): <https://github.com/blaszkin/juice-shop-devsecops/pkgs/container/juice-shop-devsecops>
  — pobranie: `docker pull ghcr.io/blaszkin/juice-shop-devsecops:latest`

## Atrybucja

Aplikacja bazowa: [OWASP Juice Shop](https://github.com/juice-shop/juice-shop) (licencja MIT,
© Bjoern Kimminich & the OWASP Juice Shop contributors). Niniejsze repozytorium wykorzystuje
ją jako cel demonstracyjny pipeline'u DevSecOps; oryginalna licencja znajduje się w pliku
[`LICENSE`](LICENSE).
