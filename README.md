# LetMeIn Routing

**Маршрутизация «снаружи в Россию» для [Happ](https://happ.su), [INCY](https://incy.cc) и [Mihomo](https://github.com/MetaCubeX/mihomo).**

> Интернет — напрямую. Российские сервисы — через российский узел.

**Таргет:** те, кто живёт за пределами РФ и упирается в обратную проблему — не блокировки, а
геоблок. Госуслуги, банки, Кинопоиск, ТВ-каналы и часть маркетплейсов просто не пускают
зарубежные IP.

👉 **[Установка в один тап](https://vizzletf.github.io/letmein-routing/)**

Это форк [roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing), развёрнутый в
обратную сторону: там всё идёт в туннель, а РФ напрямую — здесь наоборот.

> **Нужен российский выходной узел.** Без него профиль бесполезен: правила отправят российские
> домены в туннель, который выходит не в России.

---

## Профили

| Профиль | Через узел | Кому |
|---|---|---|
| **DEFAULT** | всё российское: `category-ru`, `.ru` / `.рф` / `.su`, РФ-CIDR, VK и Яндекс на зарубежных доменах | по умолчанию |
| **GEOBLOCK** | только то, что режет зарубежные IP: госуслуги, банки, онлайн-кинотеатры, ТВ | кому важнее скорость и меньше трафика через узел |
| **JSONSUB** | ничего, пустые списки | для JSON-подписок, где маршрутизация приезжает с сервера |

## Happ

| Профиль | Диплинк | JSON |
|---|---|---|
| DEFAULT | [DEFAULT.DEEPLINK](HAPP/DEFAULT.DEEPLINK) | [DEFAULT.JSON](HAPP/DEFAULT.JSON) |
| GEOBLOCK | [GEOBLOCK.DEEPLINK](HAPP/GEOBLOCK.DEEPLINK) | [GEOBLOCK.JSON](HAPP/GEOBLOCK.JSON) |
| JSONSUB | [JSONSUB.DEEPLINK](HAPP/JSONSUB.DEEPLINK) | [JSONSUB.JSON](HAPP/JSONSUB.JSON) |

Диплинк открывается **на устройстве с приложением** — со страницы установки, из файла или по QR.
Режим `onadd`: профиль добавляется и сразу становится активным.

## INCY

Те же три профиля в [INCY/](INCY/), схема `incy://`.

## Mihomo (Clash Meta)

| Файл | Для чего |
|---|---|
| [`MIHOMO/default.yaml`](MIHOMO/default.yaml) | ручная вставка, узлы через `proxy-providers` или `proxies` |
| [`MIHOMO/template_remnawave.yaml`](MIHOMO/template_remnawave.yaml) | шаблон подписки для панели Remnawave (тип MIHOMO) |

Российские узлы группа `🇷🇺 РФ Авто` отбирает по `filter: "🇷🇺"` — поправьте под имена своих узлов.

---

## Что куда идёт

### 🔵 Через российский узел

| Что | Зачем |
|---|---|
| `russia-outside` — домены, недоступные из-за границы | ядро кейса, список обновляется ежедневно |
| `category-ru`, `ru-apps`, зоны `.ru` / `.рф` / `.su` | всё остальное российское |
| РФ-CIDR (`geoip:direct`) | сервисы, у которых блок по IP, а домен нейтральный |
| VK, Яндекс, `my.games`, CDN на `.com` / `.net` / `.me` | зарубежные домены российских сервисов |
| Онлайн-кинотеатры, ТВ, банки, госуслуги | классический геоблок |

### 🟢 Напрямую

| Что | Зачем |
|---|---|
| Весь остальной интернет | он не цензурируется — гнать его в туннель незачем |
| Локальная сеть, приватные диапазоны | иначе ломается доступ к домашним сервисам |
| Торренты | чужой датацентр под свой трафик подставлять не надо |

### 🔴 Блокируется

Телеметрия Windows (`win-spy`), рекламные сети (`category-ads`).

### DNS

| Назначение | Сервер | Зачем |
|---|---|---|
| Remote (через узел) | [Яндекс](https://dns.yandex.ru/) `77.88.8.8` | российские зоны резолвим из России, иначе CDN отдаст европейские адреса, а выход будет российский — рассинхрон геолокации |
| Domestic (напрямую) | [Cloudflare](https://1.1.1.1/) `1.1.1.1` | всё остальное |

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
for f in DEFAULT GEOBLOCK JSONSUB; do
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
