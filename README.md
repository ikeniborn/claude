# init_claude - Запуск Claude Code через прокси

> Автоматическая настройка прокси и запуск Claude Code. Введите настройки один раз - используйте многократно.

---

## Что это?

Утилита для быстрого запуска Claude Code через HTTP/SOCKS5 прокси с автоматическим сохранением настроек.

### Возможности

✅ Настройка прокси один раз
✅ Автоматическое сохранение credentials
✅ Безопасное хранение паролей
✅ Поддержка HTTP, HTTPS, SOCKS5
✅ Проверка подключения перед запуском

---

## Быстрый старт

**3 простых шага:**

```bash
# 1. Установить
cd /path/to/vless/scripts
sudo ./init_claude.sh --install

# 2. Настроить прокси (один раз)
init_claude
# Proxy URL: http://username:password@host:port

# 3. Использовать
init_claude  # Запускает с сохраненными настройками
```

---

## Установка

```bash
cd /path/to/vless/scripts
sudo ./init_claude.sh --install
```

После установки команда `init_claude` доступна из любой директории.

**Проверка:**
```bash
init_claude --help
```

**Удаление:**
```bash
sudo init_claude --uninstall       # Удалить команду
init_claude --clear                # Очистить сохраненные настройки
```

---

## Использование

### Первый запуск

```bash
init_claude
```

Программа попросит ввести proxy URL в формате:
```
http://username:password@host:port
```

Пример: `http://alice:secret123@127.0.0.1:8118`

### Повторные запуски

```bash
init_claude
```

Автоматически использует сохраненные настройки. Если нужно изменить прокси, ответьте `n` на вопрос "Use saved proxy?"

### Дополнительные опции

```bash
# Установить прокси напрямую
init_claude --proxy http://user:pass@host:port

# Только протестировать подключение
init_claude --test

# Очистить сохраненные настройки
init_claude --clear

# Быстрый запуск (без проверки подключения)
init_claude --no-test
```

---

## Все команды

| Команда | Описание |
|---------|----------|
| `init_claude` | Запуск с сохраненными настройками |
| `init_claude -p URL` | Установить прокси напрямую |
| `init_claude --test` | Проверить подключение |
| `init_claude --clear` | Очистить настройки |
| `init_claude --no-test` | Запуск без проверки |
| `sudo ./init_claude.sh --install` | Установить |
| `sudo init_claude --uninstall` | Удалить |
| `init_claude --help` | Справка |

---

## Формат proxy URL

```
protocol://username:password@host:port
```

**Поддерживаемые протоколы:** `http://`, `https://`, `socks5://`

**Примеры:**
- `http://alice:secret123@127.0.0.1:8118`
- `socks5://bob:pass456@proxy.example.com:1080`
- `http://127.0.0.1:8118` (без авторизации)

---

## Примеры использования

### Первая настройка

```bash
sudo ./init_claude.sh --install
init_claude
# Proxy URL: http://alice:secret@127.0.0.1:8118
```

### Ежедневное использование

```bash
init_claude
# Use saved proxy? (Y/n): [Enter]
```

### Смена прокси

```bash
init_claude
# Use saved proxy? (Y/n): n
# Proxy URL: [новый URL]
```

### Использование с внешним прокси

```bash
# Если есть прокси-сервер
init_claude --proxy http://username:password@host:port
```

---

## Troubleshooting

### Ошибка: "Invalid URL format"

Используйте формат: `protocol://user:pass@host:port`

Правильно: `http://alice:secret@127.0.0.1:8118`

### Ошибка: "Proxy test failed"

Прокси недоступен или неверный пароль.

**Решение:**
```bash
# Проверить прокси
curl -x http://user:pass@host:port https://www.google.com

# Проверить credentials
init_claude --show-password

# Очистить и ввести заново
init_claude --clear
```

### Ошибка: "Claude Code not found"

Установите Claude Code:
```bash
npm install -g @anthropic-ai/claude-code
```

### Как изменить прокси?

```bash
# Вариант 1
init_claude
# Use saved proxy? (Y/n): n

# Вариант 2
init_claude --clear
init_claude
```

---

## Безопасность

✅ Пароли хранятся в файле с правами `600` (только владелец)
✅ Файл автоматически исключен из git
✅ Пароль маскируется в выводе: `user:****@host:port`

**Рекомендации:**
- Используйте отдельный пароль для прокси
- Очищайте credentials перед передачей проекта: `init_claude --clear`

---

**Справка:** `init_claude --help`
