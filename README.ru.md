# Docker-образ Prosody с STUN/TURN
Этот docker-образ предназначен для тех, кто хочет запустить свой собственный xmpp-сервер, и при этом не хочет разбираться в конфигурационных файлах.

## Особенности
- Основан на зарекомендовавшим себя xmpp-сервере [Prosody](https://prosody.im/).
- Настроен таким образом, чтобы проходить проверку [XMPP Compliance Tester](https://compliance.conversations.im/) с оценкой 100%.
- Поддержка аудио/видео звонков: образ включает в себя настроенный STUN/TURN сервер [coturn](https://github.com/coturn/coturn).
- Незашифрованные соединения между клиентами и сервером запрещены. E2E шифрование [опционально] обязательно.
- Минимальная настройка: задаётся только абсолютный минимум.

## Запуск
### Подготовка
Вам понадобится:
- Компьютер с внешним IP-адресом, который может запускать docker-образы для linux/amd64.
- Настройка DNS. Предположим, вы хотите чтобы ваш xmpp-сервер располагался на домене `example.com`; тогда следующие домены должны указывать (запись типа A или AAAA) на внешний IP адрес:
   - `example.com`
   - `upload.example.com`
   - `muc.example.com`
   - `proxy.example.com`
   - `pubsub.example.com`

Разумеется, вы можете использовать домен третьего или выше уровня, например, `xmpp.example.com`.

### Развёртывание
1. Создайте папку, в которую будет иметь доступ на чтение и запись пользователь с uid `9999` (пользователь может не существовать, просто выполните `chown -R 9999:9999 <ВАША-ПАПКА>`). Эта папка нужна для того, чтобы иметь возможность сохранять пользовательские данные вне зависимости от состояния docker-контейнера. Далее мы будем исходить из предположения, что это папка `/home/prosody`. В папке `/home/prosody` создайте две папки: `certs` и `data`.
2. В папке `/home/prosody/certs` должны храниться сертификаты для основного домена и для поддомена `upload.`. Предположим, вы хотите чтобы ваш xmpp-сервер располагался на домене `example.com`, тогда структура файлов и папок должна быть следующая (повторяет структуру letsencrypt):
   - certs
      - example.com
         - fullchain.pem
         - privkey.pem
      - upload.example.com
         - fullchain.pem
         - privkey.pem
3. Создайте файл docker-compose.yml следующего содержания (не забудьте поменять `example.com` на ваш домен, а `/home/prosody` - на вашу папку, где хранится база данных prosody):
```yml
services:
  server:
    image: oixa/prosody:latest
    restart: always
    ports:
      - "3478:3478/tcp"
      - "3478:3478/udp"
      - "5000:5000/tcp"
      - "5222:5222/tcp"
      - "5223:5223/tcp"
      - "5269:5269/tcp"
      - "5281:5281/tcp"
      - "50000-50100:50000-50100/udp"
    environment:
      PROSODY_ADMIN: admin@example.com
      PROSODY_ALLOW_REGISTRATION: false
      PROSODY_DOMAIN: example.com
      PROSODY_E2E_ENCRYPTION_REQUIRED: true
      PROSODY_E2E_ENCRYPTION_WHITELIST: noreply@example.com
    volumes:
      - /home/prosody/certs:/app/certs:ro
      - /home/prosody/data:/app/data
```
4. Запустите сервер командой `docker compose up -d`
5. Зарегистрировать пользователя, если вы не разрешили регистрацию через xmpp-клиенты, можно следующей командой: `docker exec -it prosody-server-1 prosodyctl register <LOGIN> <DOMAIN> <PASSWORD>`. Не забудьте подставить ваши данные!
6. Если не удаётся залогиниться, перезапустите сервер и смотрите логи в консоли: `docker compose down && docker compose up`

### Переменные окружения
- `PROSODY_ADMIN`: jid администратора сервера.
- `PROSODY_ALLOW_REGISTRATION`: разрешить ли свободную регистрацию на сервере.
- `PROSODY_DOMAIN`: домен, на котором будет работать ваш сервер.
- `PROSODY_E2E_ENCRYPTION_REQUIRED`: обязательно ли E2E-шифрование.
- `PROSODY_E2E_ENCRYPTION_WHITELIST`: список jid через запятую, для которых необязательно E2E шифрование.