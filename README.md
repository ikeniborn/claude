# init_claude - Запуск Claude Code через прокси

> Автоматическая настройка прокси и запуск Claude Code. Введите настройки один раз - используйте многократно.

---

## 📋 Содержание

- [Что это?](#что-это)
- [Варианты установки](#варианты-установки)
  - [📦 Изолированная установка (Рекомендуется)](#-изолированная-установка-рекомендуется)
  - [🖥️ Системная установка](#️-системная-установка)
- [Использование](#использование)
  - [🔍 Выбор протокола прокси](#-выбор-протокола-прокси-https-vs-http-vs-socks5)
- [Обновление](#обновление)
- [Troubleshooting](#troubleshooting)

---

## Что это?

Утилита для быстрого запуска Claude Code через HTTP/HTTPS прокси с автоматическим сохранением настроек.

### Возможности

✅ Настройка прокси один раз
✅ Автоматическое сохранение credentials
✅ Безопасное хранение паролей
✅ Поддержка HTTP и HTTPS прокси (SOCKS5 НЕ поддерживается)
✅ Проверка подключения перед запуском
✅ **Изолированная установка** - портабельность через git
✅ **Воспроизводимые версии** через lockfile

---

## Варианты установки

Выберите подходящий вариант установки в зависимости от ваших потребностей.

### 📦 Изолированная установка (Рекомендуется)

Изолированная установка размещает NVM, Node.js и Claude Code в директории проекта (`.nvm-isolated/`). Это обеспечивает полную портабельность и избегает конфликтов с системными установками.

#### Когда использовать:

✅ Нужна портабельность между машинами
✅ Избежание конфликтов с системным Node.js/NVM
✅ Работа без sudo на других машинах
✅ Воспроизводимые версии через lockfile
✅ Возможность коммитить окружение в git

#### Первая установка

```bash
# Клонировать репозиторий
git clone https://github.com/ikeniborn/claude.git
cd claude

# Установить в изолированное окружение
./init_claude.sh --isolated-install

# Это создаст:
# - .nvm-isolated/                  (~278MB, в git)
# - .nvm-isolated-lockfile.json     (lockfile с версиями, в git)
```

#### Установка на другой машине (git clone)

**Вариант 1: Использование полного окружения из git**

```bash
# 1. Клонировать репозиторий (включает .nvm-isolated/)
git clone https://github.com/ikeniborn/claude.git
cd claude

# 2. Восстановить симлинки после git clone
./init_claude.sh --repair-isolated

# 3. Готово! Запуск
./init_claude.sh
```

**Вариант 2: Установка из lockfile (легче для git)**

```bash
# 1. Клонировать репозиторий (включает только lockfile)
git clone https://github.com/ikeniborn/claude.git
cd claude

# 2. Установить из lockfile (точные версии)
./init_claude.sh --install-from-lockfile

# 3. Готово! Запуск
./init_claude.sh
```

#### Проверка статуса

```bash
# Проверить статус изолированного окружения
./init_claude.sh --check-isolated

# Вывод:
# - Версии Node.js, npm, Claude Code
# - Статус симлинков (✓/✗)
# - Содержимое lockfile
```

#### Обновление Claude Code

```bash
# Обновить Claude Code в изолированном окружении
./init_claude.sh --update

# После обновления автоматически:
# ✅ Обновляется Claude Code к последней версии
# ✅ Обновляется lockfile с новой версией
# ✅ Восстанавливаются симлинки и права доступа

# Проверить что lockfile обновился корректно
./init_claude.sh --check-isolated
# Должны совпадать:
# - Claude Code: X.X.X
# - claudeCodeVersion: "X.X.X" (в lockfile)
```

**Примечание:** Начиная с версии от 24.10.2025, проблема с обновлением lockfile исправлена. Lockfile теперь всегда обновляется автоматически вместе с Claude Code.

#### Очистка

```bash
# Удалить изолированное окружение (сохраняет lockfile)
./init_claude.sh --cleanup-isolated

# Для переустановки:
./init_claude.sh --install-from-lockfile
```

---

### 🖥️ Системная установка

Системная установка размещает команду `init_claude` в `/usr/local/bin/` и использует системный или существующий NVM для Claude Code.

#### Когда использовать:

✅ Нужна глобальная установка для всех пользователей
✅ Уже есть системный Node.js
✅ Не требуется портабельность

#### Установка

```bash
# Установить глобально (требует sudo)
cd /path/to/claude
sudo ./init_claude.sh --install

# После установки команда доступна из любой директории
init_claude --help
```

**Автоматическая установка зависимостей:**

При первой установке скрипт автоматически проверит и предложит установить:
- ✅ Node.js и npm (если отсутствуют) - через официальный репозиторий NodeSource
- ✅ Claude Code (если отсутствует) - через `npm install -g @anthropic-ai/claude-code`

#### Обновление Claude Code

```bash
# Проверить доступные обновления
init_claude --check-update

# Обновить к последней версии
sudo init_claude --update  # Для системной установки
# или
init_claude --update       # Для NVM установки (без sudo)
```

#### Удаление

```bash
# Удалить команду (сохраняет настройки прокси)
sudo init_claude --uninstall

# Очистить сохраненные настройки прокси
init_claude --clear
```

---

## Использование

После установки (изолированной или системной) использование одинаковое.

### Первый запуск

```bash
# Изолированная установка
./init_claude.sh

# Системная установка
init_claude
```

Программа попросит ввести proxy URL в формате:
```
http://username:password@host:port
https://username:password@host:port
```

**⚠️ Важно:** SOCKS5 прокси НЕ поддерживаются Claude Code из-за ограничений библиотеки undici.

**Примеры:**
```bash
http://alice:secret123@127.0.0.1:8118
https://user:pass@proxy.example.com:8118
```

### Последующие запуски

```bash
# Использует сохраненные настройки автоматически
./init_claude.sh  # изолированная
init_claude       # системная
```

### Безопасная работа с HTTPS прокси

**Рекомендуется** использовать `--proxy-ca` для HTTPS прокси с самоподписанными сертификатами:

```bash
# SECURE (рекомендуется)
./init_claude.sh --proxy https://proxy:8118 --proxy-ca /path/to/proxy-cert.pem
```

**Не рекомендуется** использовать `--proxy-insecure` (отключает TLS для всех подключений):

```bash
# ⚠️ INSECURE (не рекомендуется)
./init_claude.sh --proxy https://proxy:8118 --proxy-insecure
```

Как получить сертификат прокси:
```bash
# Экспортировать сертификат
openssl s_client -showcerts -connect proxy.example.com:8118 < /dev/null 2>/dev/null | \
  openssl x509 -outform PEM > proxy-cert.pem

# Или получить справку
./init_claude.sh --help-export-cert
```

### 🔍 Выбор протокола прокси: HTTPS vs HTTP vs SOCKS5

#### Поддержка протоколов (официальная документация)

| Протокол | Статус | Рекомендация |
|----------|--------|--------------|
| **HTTPS** | ✅ Полная поддержка | **✅ Рекомендуется** |
| **HTTP** | ✅ Полная поддержка | ⚠️ Fallback вариант |
| **SOCKS5** | ❌ **НЕ поддерживается** | ❌ Вызывает краш приложения |

**Источник:** [Claude Code: Corporate Proxy Configuration](https://docs.claude.com/en/docs/claude-code/corporate-proxy)

---

#### ✅ HTTPS прокси (рекомендуется)

**Преимущества:**
- ✅ Официально рекомендован Anthropic
- ✅ Шифрование соединения клиент↔прокси
- ✅ Защита credentials от перехвата
- ✅ Поддержка самоподписанных сертификатов через `NODE_EXTRA_CA_CERTS`

**Недостатки:**
- ⚠️ **Критическая уязвимость:** undici не проверяет сертификаты целевых серверов ([HackerOne #1583680](https://hackerone.com/reports/1583680))
- ⚠️ Прокси-сервер может перехватывать весь HTTPS трафик (MitM)
- ⚠️ Требует доверия к прокси-серверу

**Когда использовать:**
- ✅ Корпоративные сети с доверенным прокси
- ✅ Приватные прокси в вашем контроле
- ✅ Когда важна защита credentials

**Конфигурация:**
```bash
# С сертификатом (SECURE)
./init_claude.sh --proxy https://proxy:8118 --proxy-ca /path/to/cert.pem

# Небезопасно (не рекомендуется)
./init_claude.sh --proxy https://proxy:8118 --proxy-insecure
```

---

#### ⚠️ HTTP прокси (fallback)

**Преимущества:**
- ✅ Официально поддерживается
- ✅ Простая настройка (не требует сертификаты)
- ✅ Работает как fallback если HTTPS недоступен

**Недостатки:**
- ❌ **Весь трафик передается открытым текстом** между клиентом и прокси
- ❌ Прокси видит все запросы, включая API ключи Claude
- ❌ Уязвим к перехвату на сетевом уровне
- ❌ Та же уязвимость undici с непроверкой сертификатов

**Когда использовать:**
- ⚠️ Только для локальных прокси (localhost)
- ⚠️ Разработка и тестирование
- ❌ НЕ использовать через интернет
- ❌ НЕ использовать в production

**Конфигурация:**
```bash
# Только для localhost!
./init_claude.sh --proxy http://localhost:8118
```

---

#### ❌ SOCKS5 прокси (НЕ РАБОТАЕТ)

**Статус:** **Полностью не поддерживается**

**Проблема:**
- Claude Code использует библиотеку `undici` для HTTP запросов
- undici [не поддерживает SOCKS протокол](https://github.com/nodejs/undici/issues/2224)
- При попытке использования **приложение крашится** с ошибкой:
  ```
  InvalidArgumentError: Invalid URL protocol:
  the URL must start with `http:` or `https:`
  ```

**Официальный комментарий Anthropic:**
> "This is a limitation of the undici proxy library that we use."
> — [GitHub Issue #3387](https://github.com/anthropics/claude-code/issues/3387)

**Обходные пути:**
1. **HTTP/HTTPS прокси** - используйте вместо SOCKS5
2. **Privoxy/squid** - локальный переходник SOCKS5 → HTTP:
   ```bash
   # Установить privoxy
   sudo apt install privoxy

   # Настроить forward-socks5 в /etc/privoxy/config
   forward-socks5 / 127.0.0.1:1080 .

   # Использовать privoxy как HTTP прокси
   ./init_claude.sh --proxy http://127.0.0.1:8118
   ```
3. **LLM Gateway** (LiteLLM) с поддержкой SOCKS5

---

#### 🎯 Рекомендации по выбору

**Для корпоративных сетей:**
```bash
# ЛУЧШИЙ ВАРИАНТ: HTTPS с корпоративным сертификатом
export HTTPS_PROXY=https://proxy.company.com:8118
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/company-proxy-ca.pem
./init_claude.sh
```

**Для разработки (localhost):**
```bash
# ПРИЕМЛЕМО: HTTP для локального прокси
export HTTP_PROXY=http://localhost:8118
export NO_PROXY="localhost,127.0.0.1"
./init_claude.sh
```

**Для production:**
```bash
# Рассмотрите LiteLLM Gateway вместо прямого прокси:
# - Продвинутая аутентификация (NTLM, Kerberos)
# - Централизованное управление безопасностью
# - Обход ограничений undici
```

---

#### ⚠️ Важные предупреждения безопасности

**Критическая уязвимость undici ProxyAgent:**

Независимо от использования HTTPS или HTTP прокси, библиотека undici имеет фундаментальную проблему:

- ❌ **Не проверяет сертификаты** целевых HTTPS серверов при работе через прокси
- ❌ Весь HTTPS трафик **потенциально уязвим к MitM атакам** со стороны прокси
- ❌ При HTTP прокси **весь трафик передается открытым текстом** клиент↔прокси

**Это означает:**
- Прокси-сервер может видеть и модифицировать все запросы к Anthropic API
- Прокси видит ваши API ключи, код проекта, персональные данные
- **Используйте только доверенные прокси-серверы**

**Источник:** [HackerOne Report #1583680](https://hackerone.com/reports/1583680)

---

#### 📊 Сравнительная таблица

| Критерий | HTTPS | HTTP | SOCKS5 |
|----------|-------|------|--------|
| **Официальная поддержка** | ✅ Рекомендуется | ✅ Поддерживается | ❌ Не работает |
| **Безопасность клиент↔прокси** | ✅ Шифрование | ❌ Открытый текст | N/A |
| **Безопасность прокси↔API** | ⚠️ Без проверки сертификатов | ⚠️ Без проверки сертификатов | N/A |
| **Простота настройки** | ⚠️ Требует сертификаты | ✅ Простая | N/A |
| **Корпоративные сети** | ✅✅ Лучший выбор | ⚠️ Не рекомендуется | ❌ Невозможно |
| **Локальная разработка** | ✅ Хороший выбор | ✅ Приемлемо | ❌ Невозможно |
| **Production** | ✅ С доверенным прокси | ❌ Не рекомендуется | ❌ Невозможно |

---

### Другие команды

```bash
# Изменить прокси
./init_claude.sh --proxy http://new:proxy@host:port

# Запустить без прокси
./init_claude.sh --no-proxy

# Тестировать прокси без запуска Claude
./init_claude.sh --test

# Очистить сохраненные настройки
./init_claude.sh --clear

# Передать аргументы в Claude Code
./init_claude.sh -- --model claude-3-opus
```

---

## Обновление

### Изолированная установка

```bash
# Обновить Claude Code
./init_claude.sh --update

# Автоматически:
# ✅ Обновляет Claude Code к последней версии
# ✅ Обновляет lockfile с новой версией
# ✅ Восстанавливает симлинки и права доступа

# Проверить статус после обновления
./init_claude.sh --check-isolated

# Проверьте, что версии совпадают:
# Claude Code: 2.0.26
# claudeCodeVersion: "2.0.26" (в lockfile)
```

**✨ Исправление (24.10.2025):** Проблема с обновлением lockfile в изолированной среде была исправлена. Теперь lockfile всегда обновляется автоматически при запуске `--update`.

### Системная установка

```bash
# Проверить доступные обновления
init_claude --check-update

# Обновить (требует sudo для системной установки)
sudo init_claude --update

# Для NVM установки (без sudo)
init_claude --update
```

---

## Troubleshooting

### SOCKS5 прокси - краш приложения

**Проблема:** `InvalidArgumentError: Invalid URL protocol: the URL must start with 'http:' or 'https:'`

**Причина:** Claude Code НЕ поддерживает SOCKS5 из-за ограничений библиотеки undici.

**Решение:** См. раздел [SOCKS5 прокси не работает](#socks5-прокси-не-работает) ниже или используйте HTTP/HTTPS прокси.

---

### После git clone симлинки не работают

**Симптомы:**
- `./init_claude.sh` выдает ошибки
- Claude Code не найден
- Команды npm/node не работают

**Решение:**
```bash
# Восстановить симлинки и права
./init_claude.sh --repair-isolated

# Проверить статус
./init_claude.sh --check-isolated
```

### Проверка симлинков

```bash
./init_claude.sh --check-isolated

# Вывод покажет статус всех симлинков:
# Symlinks Status:
#   ✓ npm
#   ✓ npx
#   ✓ corepack
#   ✓ claude
#
# Если есть ✗ - запустить --repair-isolated
```

### Прокси не работает

```bash
# Тестировать подключение
./init_claude.sh --test

# Очистить настройки и ввести заново
./init_claude.sh --clear
./init_claude.sh
```

### HTTPS прокси с самоподписанным сертификатом

**Проблема:** `SSL certificate problem: self signed certificate`

**Решение 1 (безопасно):**
```bash
# Экспортировать сертификат прокси
openssl s_client -showcerts -connect proxy:8118 < /dev/null 2>/dev/null | \
  openssl x509 -outform PEM > proxy-cert.pem

# Использовать с --proxy-ca
./init_claude.sh --proxy https://proxy:8118 --proxy-ca ./proxy-cert.pem
```

**Решение 2 (небезопасно):**
```bash
# Отключить проверку TLS (не рекомендуется)
./init_claude.sh --proxy https://proxy:8118 --proxy-insecure
```

### Lockfile не обновляется после обновления

**Симптомы:**
- Claude Code обновился, но версия в lockfile осталась старой
- `./init_claude.sh --check-isolated` показывает разные версии:
  ```
  Claude Code: 2.0.26
  claudeCodeVersion: "2.0.25"  ← НЕ СОВПАДАЕТ
  ```

**Решение:**

✅ **Исправлено в версии от 24.10.2025** - обновите скрипт:
```bash
git pull
./init_claude.sh --update
```

Для старых версий скрипта:
```bash
# Вручную обновить lockfile
bash -c 'source ./init_claude.sh && save_isolated_lockfile'

# Проверить результат
./init_claude.sh --check-isolated
```

### Обновление не работает (NVM)

**Симптомы:** `ENOTEMPTY` ошибки при обновлении

**Решение для изолированной установки:**
```bash
# Очистить и переустановить
./init_claude.sh --cleanup-isolated
./init_claude.sh --install-from-lockfile
```

**Решение для системного NVM:**
```bash
# Запустить обновление повторно (автоматическая очистка)
init_claude --update

# Или вручную:
rm -rf ~/.nvm/versions/node/*/lib/node_modules/@anthropic-ai/.claude-code-*
npm install -g @anthropic-ai/claude-code@latest
```

### Git на Windows - симлинки не работают

**Проблема:** На Windows симлинки могут быть сохранены как текстовые файлы.

**Решение:**
```bash
# Включить поддержку симлинков в git
git config --global core.symlinks true

# Пересоздать репозиторий
cd ..
rm -rf claude
git clone https://github.com/ikeniborn/claude.git
cd claude

# Восстановить симлинки
./init_claude.sh --repair-isolated
```

### Конфликт изолированной и системной установки

**Симптомы:** Скрипт использует неправильную установку

**Решение:**
```bash
# Проверить какая установка активна
./init_claude.sh --check-isolated

# Для принудительного использования изолированной:
# Убедитесь что .nvm-isolated/ существует и запускаете ./init_claude.sh

# Для использования системной:
# Используйте команду init_claude (без ./)
init_claude
```

### SOCKS5 прокси не работает

**Симптомы:**
- Приложение крашится с ошибкой: `InvalidArgumentError: Invalid URL protocol`
- Ошибка: `the URL must start with 'http:' or 'https:'`

**Причина:**
- Claude Code использует библиотеку undici, которая **НЕ поддерживает SOCKS5**
- Это ограничение на уровне зависимости, не специфичное для Claude Code

**Решение:**

**Вариант 1: Использовать HTTP/HTTPS прокси**
```bash
# Вместо SOCKS5 используйте HTTP/HTTPS
./init_claude.sh --proxy https://proxy:8118
```

**Вариант 2: Прокси-переходник (Privoxy)**
```bash
# Установить privoxy
sudo apt install privoxy

# Настроить /etc/privoxy/config
echo "forward-socks5 / 127.0.0.1:1080 ." | sudo tee -a /etc/privoxy/config

# Перезапустить
sudo systemctl restart privoxy

# Использовать privoxy как HTTP прокси
./init_claude.sh --proxy http://127.0.0.1:8118
```

**Вариант 3: LLM Gateway**
```bash
# Использовать LiteLLM Gateway с поддержкой SOCKS5
# См. https://docs.litellm.ai/
```

**Официальный источник:**
- [GitHub Issue #3387](https://github.com/anthropics/claude-code/issues/3387)
- [Claude Docs: Corporate Proxy](https://docs.claude.com/en/docs/claude-code/corporate-proxy)

---

## Дополнительная информация

### Файлы

**Изолированная установка:**
- `.nvm-isolated/` - изолированная установка NVM (~278MB, в git)
- `.nvm-isolated-lockfile.json` - lockfile с версиями (в git)
- `.claude_proxy_credentials` - прокси credentials (chmod 600, НЕ в git)

**Системная установка:**
- `/usr/local/bin/init_claude` - глобальная команда
- `~/.claude_proxy_credentials` - прокси credentials (chmod 600)

### Справка

```bash
# Полная справка
./init_claude.sh --help
init_claude --help

# Справка по экспорту сертификатов
./init_claude.sh --help-export-cert
```

### Поддержка

- Репозиторий: https://github.com/ikeniborn/claude
- Issues: https://github.com/ikeniborn/claude/issues
