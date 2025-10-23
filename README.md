# init_claude - Запуск Claude Code через прокси

> Автоматическая настройка прокси и запуск Claude Code. Введите настройки один раз - используйте многократно.

---

## 📋 Содержание

- [Что это?](#что-это)
- [Варианты установки](#варианты-установки)
  - [📦 Изолированная установка (Рекомендуется)](#-изолированная-установка-рекомендуется)
  - [🖥️ Системная установка](#️-системная-установка)
- [Использование](#использование)
- [Обновление](#обновление)
- [Troubleshooting](#troubleshooting)

---

## Что это?

Утилита для быстрого запуска Claude Code через HTTP/SOCKS5 прокси с автоматическим сохранением настроек.

### Возможности

✅ Настройка прокси один раз
✅ Автоматическое сохранение credentials
✅ Безопасное хранение паролей
✅ Поддержка HTTP, HTTPS, SOCKS5
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
# - Обновляется lockfile
# - Восстанавливаются симлинки
```

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
socks5://username:password@host:port
```

**Примеры:**
```bash
http://alice:secret123@127.0.0.1:8118
https://user:pass@proxy.example.com:8118
socks5://bob:pass456@proxy.example.com:1080
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
# - Обновляет Claude Code к последней версии
# - Обновляет lockfile
# - Восстанавливает симлинки

# Проверить статус после обновления
./init_claude.sh --check-isolated
```

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
