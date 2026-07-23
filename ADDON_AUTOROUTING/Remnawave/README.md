# Remnawave — раздача routing-профиля через подписку

Happ не берёт маршрутизацию из шаблона подписки: он читает её из HTTP-заголовка `routing:`,
который панель отдаёт из поля **`happRouting`** в Subscription Settings. Положили туда диплинк —
его получают все Happ-клиенты, и при каждом обновлении подписки правила подменяются атомарно
(ядро продолжает работать на старых, пока качаются новые гео-базы).

## Залить профиль

```bash
LINK="$(curl -fsSL https://raw.githubusercontent.com/VizzleTF/letmein-routing/main/HAPP/DEFAULT.DEEPLINK | tr -d '\n\r')"

curl -s -X PATCH "https://<panel>/api/subscription-settings" \
  -H "Authorization: Bearer $REMNAWAVE_API_TOKEN" -H 'Content-Type: application/json' \
  -d "$(jq -n --arg u "<subscription-settings-uuid>" --arg r "$LINK" '{uuid:$u, happRouting:$r}')"
```

`uuid` берётся из `GET /api/subscription-settings`.

## Грабли

- **В поле помещается ровно ОДИН диплинк.** Две ссылки через перенос строки PATCH принимает
  (отвечает 200, значение сохраняется), но дальше подписка отдаёт **500 всем запросам с
  User-Agent `Happ`** — остальные клиенты получают 200, поэтому поломку легко не заметить.
  Проверяйте после каждой правки:

  ```bash
  curl -s -o /dev/null -w '%{http_code}\n' -A 'Happ/1.0' "https://<panel>/api/sub/<shortUuid>"
  ```

- Поле глобальное: разным пользователям разные профили через него не раздать. Второй профиль —
  только ссылкой или QR.
- Гео-базы Happ перекачивает, лишь когда `LastUpdated` вырос, и **не чаще раза в неделю**.
  Чаще, чем раз в неделю, обновлять `happRouting` ради баз бессмысленно.

## Обновление по расписанию

[`update.sh`](update.sh) — тянет свежий диплинк из этого репозитория, кладёт его в `happRouting`,
затем проверяет подписку с UA `Happ` и **откатывает значение, если ответ не 200**.

```bash
install -d /opt/letmein-routing
curl -fsSL https://raw.githubusercontent.com/VizzleTF/letmein-routing/main/ADDON_AUTOROUTING/Remnawave/update.sh \
  -o /opt/letmein-routing/update.sh
chmod +x /opt/letmein-routing/update.sh

cat > /etc/letmein-routing.env <<'EOF'
PANEL_URL=https://panel.example.org
API_TOKEN=<remnawave api token>
SETTINGS_UUID=<uuid из GET /api/subscription-settings>
HEALTH_SHORT_UUID=<shortUuid любого активного пользователя>
PROFILE=DEFAULT           # DEFAULT | GEOBLOCK | JSONSUB
EOF
chmod 600 /etc/letmein-routing.env

printf '30 6 * * 0 root /opt/letmein-routing/update.sh >> /var/log/letmein-routing.log 2>&1\n' \
  > /etc/cron.d/letmein-routing
```

Раз в неделю — ровно потому, что чаще Happ гео-базы всё равно не возьмёт.
