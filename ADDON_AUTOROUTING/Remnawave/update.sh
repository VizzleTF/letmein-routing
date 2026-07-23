#!/bin/bash
# Обновляет Happ routing-профиль в панели Remnawave: тянет свежий диплинк LetMeIn,
# кладёт его в happRouting и проверяет, что подписка после этого жива.
# Если подписка отвечает не 200 для UA Happ — значение откатывается обратно.
#
# Настройки в /etc/letmein-routing.env (или в переменных окружения):
#   PANEL_URL, API_TOKEN, SETTINGS_UUID, HEALTH_SHORT_UUID, PROFILE, SQUAD_UUID
#
# SQUAD_UUID задан — профиль кладётся в subscriptionSettings этого внешнего сквада
# (перекрывает глобальный happRouting, так разным группам раздаются разные профили).
# Токен читается в переменную и никуда не печатается.
set -uo pipefail

ENV_FILE="${ENV_FILE:-/etc/letmein-routing.env}"
[ -r "$ENV_FILE" ] && . "$ENV_FILE"

: "${PANEL_URL:?PANEL_URL не задан}"
: "${API_TOKEN:?API_TOKEN не задан}"
: "${SETTINGS_UUID:?SETTINGS_UUID не задан}"
SQUAD_UUID="${SQUAD_UUID:-}"
PROFILE="${PROFILE:-DEFAULT}"
RAW="https://raw.githubusercontent.com/VizzleTF/letmein-routing/main/HAPP/${PROFILE}.DEEPLINK"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR $*"; exit 1; }

api() { # METHOD PATH [curl args...]
  local m="$1" p="$2"; shift 2
  curl -s -m 25 -X "$m" -H "Authorization: Bearer $API_TOKEN" -H 'Content-Type: application/json' \
       "${PANEL_URL}${p}" "$@"
}

LINK="$(curl -fsSL -m 20 --retry 3 "$RAW" | tr -d '\n\r')"
[ -n "$LINK" ] || die "не удалось скачать $RAW"
case "$LINK" in happ://routing/*) ;; *) die "скачанное не похоже на диплинк" ;; esac

if [ -n "$SQUAD_UUID" ]; then
  PREV="$(api GET /api/external-squads \
    | jq -r --arg u "$SQUAD_UUID" '.response.externalSquads[] | select(.uuid==$u) | .subscriptionSettings.happRouting // ""')"
else
  PREV="$(api GET /api/subscription-settings | jq -r '.response.happRouting // ""')"
fi
if [ "$PREV" = "$LINK" ]; then
  log "no change (профиль $PROFILE уже актуален)"; exit 0
fi

set_routing() { # $1 = значение ("" -> null)
  if [ -n "$SQUAD_UUID" ]; then
    api PATCH /api/external-squads -d "$(jq -n --arg u "$SQUAD_UUID" --arg r "$1" \
      '{uuid:$u, subscriptionSettings:{happRouting:(if $r=="" then null else $r end)}}')"
  else
    api PATCH /api/subscription-settings -d "$(jq -n --arg u "$SETTINGS_UUID" --arg r "$1" \
      '{uuid:$u, happRouting:(if $r=="" then null else $r end)}')"
  fi
}

set_routing "$LINK" | jq -e '.response != null' >/dev/null || die "PATCH happRouting не прошёл"

# Health-check: битое значение валит подписку только для UA Happ, остальные клиенты
# получают 200 и поломки не видно — поэтому проверяем именно этим UA.
if [ -n "${HEALTH_SHORT_UUID:-}" ]; then
  CODE="$(curl -s -o /dev/null -m 20 -w '%{http_code}' -A 'Happ/1.0' \
          "${PANEL_URL}/api/sub/${HEALTH_SHORT_UUID}")"
  if [ "$CODE" != 200 ]; then
    set_routing "$PREV" >/dev/null
    die "подписка отдала $CODE для UA Happ — happRouting откачен"
  fi
  log "health-check ok (200)"
else
  log "WARN health-check пропущен: HEALTH_SHORT_UUID не задан"
fi

log "OK залит профиль $PROFILE (${#LINK} символов)${SQUAD_UUID:+ в сквад $SQUAD_UUID}"
