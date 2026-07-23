# LetMeIn / LetMeOut Routing

**Профили маршрутизации для [Happ](https://happ.su), [INCY](https://incy.cc) и [Mihomo](https://github.com/MetaCubeX/mihomo) — в обе стороны.**

| | | |
|---|---|---|
| **LetMeOut** | 🇷🇺 → 🌍 | вы в России, нужен доступ к заблокированному. Всё в туннель, РФ напрямую. Нужен **зарубежный** узел |
| **LetMeIn** | 🌍 → 🇷🇺 | вы за границей, упираетесь в геоблок: госуслуги, банки, Кинопоиск не пускают зарубежные IP. Всё напрямую, РФ в туннель. Нужен **российский** узел |

👉 **[Установка в один тап](https://vizzletf.github.io/letmein-routing/)**

Форк [roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing): `LetMeOut` — их
логика с нашими правками, `LetMeIn` — та же схема, развёрнутая в обратную сторону.

---

## Профили

| Профиль | Направление | Через узел идёт | Кому |
|---|---|---|---|
| **OUT** | 🇷🇺 → 🌍 | всё, кроме РФ-доменов, игр и торрентов | из России наружу |
| **IN** | 🌍 → 🇷🇺 | всё российское: `category-ru`, `.ru` / `.рф` / `.su`, РФ-CIDR, VK и Яндекс на зарубежных доменах | по умолчанию для тех, кто за границей |
| **IN-GEOBLOCK** | 🌍 → 🇷🇺 | только то, что режет зарубежные IP: госуслуги, банки, кинотеатры, ТВ | кому важнее скорость и меньше трафика через узел |
| **JSONSUB** | — | ничего, пустые списки | для JSON-подписок, где маршрутизация приезжает с сервера |

## Happ

| Профиль | Диплинк | JSON |
|---|---|---|
| OUT | [OUT.DEEPLINK](HAPP/OUT.DEEPLINK) | [OUT.JSON](HAPP/OUT.JSON) |
| IN | [IN.DEEPLINK](HAPP/IN.DEEPLINK) | [IN.JSON](HAPP/IN.JSON) |
| IN-GEOBLOCK | [IN-GEOBLOCK.DEEPLINK](HAPP/IN-GEOBLOCK.DEEPLINK) | [IN-GEOBLOCK.JSON](HAPP/IN-GEOBLOCK.JSON) |
| JSONSUB | [JSONSUB.DEEPLINK](HAPP/JSONSUB.DEEPLINK) | [JSONSUB.JSON](HAPP/JSONSUB.JSON) |

Диплинк открывается **на устройстве с приложением** — со страницы установки, из файла или по QR.
Режим `onadd`: профиль добавляется и сразу становится активным.

**Своя инфраструктура.** Если раздаёте профиль своим пользователям, добавьте в `DirectSites`
домены панели и подписки — иначе обновление подписки пойдёт через туннель.

## INCY

Те же четыре профиля в [INCY/](INCY/), схема `incy://`.

## Mihomo (Clash Meta)

Пока только направление **LetMeIn** (снаружи в Россию):

| Файл | Для чего |
|---|---|
| [`MIHOMO/default.yaml`](MIHOMO/default.yaml) | ручная вставка, узлы через `proxy-providers` или `proxies` |
| [`MIHOMO/template_remnawave.yaml`](MIHOMO/template_remnawave.yaml) | шаблон подписки для панели Remnawave (тип MIHOMO) |

Российские узлы группа `🇷🇺 РФ Авто` отбирает по `filter: "🇷🇺"` — поправьте под имена своих узлов.

---

## Что куда идёт

### LetMeIn — 🔵 через российский узел

| Что | Зачем |
|---|---|
| `russia-outside` — домены, недоступные из-за границы | ядро кейса, список обновляется ежедневно |
| `category-ru`, `ru-apps`, зоны `.ru` / `.рф` / `.su` | всё остальное российское |
| РФ-CIDR (`geoip:direct`) | сервисы, у которых блок по IP, а домен нейтральный |
| VK, Яндекс, `my.games`, CDN на `.com` / `.net` / `.me` | зарубежные домены российских сервисов |
| Онлайн-кинотеатры, ТВ, банки, госуслуги | классический геоблок |

### LetMeIn — 🟢 напрямую

| Что | Зачем |
|---|---|
| Весь остальной интернет | он не цензурируется — гнать его в туннель незачем |
| Локальная сеть, приватные диапазоны | иначе ломается доступ к домашним сервисам |
| Торренты | чужой датацентр под свой трафик подставлять не надо |

### LetMeOut — в туннель

YouTube, Telegram, Discord, GitHub, Google Play, Twitch, AI-сервисы (OpenAI, Anthropic, Gemini,
DeepMind), Apple, Microsoft — и всё несовпавшее, потому что `GlobalProxy: true`.
Напрямую: РФ-домены и CIDR, игровые платформы, торренты.

Отличия от стокового roscomvpn: Apple и Microsoft у нас **в туннеле**, а не напрямую;
торренты — `DIRECT`, а не `BLOCK`; AI и Discord прописаны явными правилами.

### 🔴 Блокируется (оба направления)

Телеметрия Windows (`win-spy`), рекламные сети (`category-ads`).

### DNS

**LetMeIn:**

| Назначение | Сервер | Зачем |
|---|---|---|
| Remote (через узел) | [Яндекс](https://dns.yandex.ru/) `77.88.8.8` | российские зоны резолвим из России, иначе CDN отдаст европейские адреса, а выход будет российский — рассинхрон геолокации |
| Domestic (напрямую) | [Cloudflare](https://1.1.1.1/) `1.1.1.1` | всё остальное |

**LetMeOut** — зеркально: Google `8.8.8.8` через туннель, Яндекс `77.88.8.8` напрямую.

---

## Интеграция с панелями

[Remnawave](ADDON_AUTOROUTING/Remnawave/) — как отдавать routing-профиль всем клиентам через
подписку и как обновлять его по расписанию (готовый скрипт прилагается).

## Автообновление

GitHub Actions ([`update-configs.yml`](.github/workflows/update-configs.yml)) раз в сутки:
подтягивает свежие теги [roscomvpn-geoip](https://github.com/hydraponique/roscomvpn-geoip) и
[roscomvpn-geosite](https://github.com/hydraponique/roscomvpn-geosite), бампает `LastUpdated`
(только если пины реально изменились — иначе клиенты качали бы базы впустую), пересобирает
диплинки и публикует страницу на GitHub Pages.

Диплинк длиннее **2953 байт** не влезает в QR — workflow падает с ошибкой, если списки в JSON
раздулись до этого предела.

## Правки

```bash
# поправить HAPP/*.JSON, затем локально пересобрать диплинки:
for f in IN IN-GEOBLOCK OUT JSONSUB; do
  printf 'happ://routing/onadd/%s\n' "$(jq -c . HAPP/$f.JSON | base64 -w0)" > HAPP/$f.DEEPLINK
  printf 'incy://routing/onadd/%s\n' "$(jq -c . INCY/$f.JSON | base64 -w0)" > INCY/$f.DEEPLINK
done

# страница (нужен qrencode):
python3 site/build.py && python3 -m http.server -d _site
```

Пуш в `main` пересоберёт всё сам.

---

## Благодарности

- [hydraponique](https://github.com/hydraponique) — исходный roscomvpn-routing и гео-базы
- [itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains) — список `russia_outside`
- [legiz-ru](https://github.com/legiz-ru), [Davoyan](https://github.com/Davoyan) — rule-set'ы для Mihomo
