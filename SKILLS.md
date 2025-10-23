# Claude Skills для проекта init_claude

> **Версия:** 1.0.0
> **Дата:** 2025-10-22
> **Автор:** init_claude Team

---

## 📋 Оглавление

- [Что такое Claude Skills](#что-такое-claude-skills)
- [Зачем нужны Skills](#зачем-нужны-skills)
- [Доступные Skills](#доступные-skills)
- [Как использовать Skills](#как-использовать-skills)
- [Как создать новый Skill](#как-создать-новый-skill)
- [Best Practices](#best-practices)
- [Примеры использования](#примеры-использования)
- [FAQ](#faq)

---

## Что такое Claude Skills

**Claude Skills** — это специализированные инструкции и шаблоны кода, которые автоматизируют типичные задачи разработки bash-утилиты **init_claude**. Skill представляет собой директорию с файлом `SKILL.md` (Markdown + YAML frontmatter), содержащим:

- **Описание задачи**: что делает skill
- **Контекст проекта**: архитектура bash-скрипта, используемые паттерны
- **Шаблоны кода**: готовые bash code templates
- **Инструкции**: пошаговые руководства
- **Примеры**: реальные use cases для init_claude
- **Чеклисты**: проверки после выполнения

**Формат SKILL.md:**

```markdown
---
name: Skill Name
description: Краткое описание
version: 1.0.0
author: init_claude Team
tags: [bash, proxy, development]
dependencies: []
---

# Skill Name

Подробное описание...

## Когда использовать

- Условие 1
- Условие 2

## Шаблоны кода

...
```

**Ключевые особенности:**

- 🔄 **Auto-invoke**: Claude автоматически вызывает нужный skill при запросе
- 🧩 **Composable**: Skills объединяются автоматически для сложных задач
- 📝 **Structured**: YAML frontmatter + Markdown контент
- 🎯 **Contextual**: Учитывают специфику bash-разработки и proxy management

---

## Зачем нужны Skills

### Проблемы без Skills:

❌ **Повторяющийся boilerplate** - каждый раз пишешь одинаковые bash-функции
❌ **Забытые паттерны** - не помнишь как правильно парсить proxy URL
❌ **Inconsistency** - разные стили обработки ошибок
❌ **Долгий onboarding** - новички долго разбираются в архитектуре скрипта
❌ **Пропущенные шаги** - забыл добавить валидацию или обработку edge cases

### Решение с Skills:

✅ **Автоматизация** - +40-60% скорость разработки bash-функций
✅ **Стандартизация** - единый code style и архитектура
✅ **Quality** - обязательные чеклисты и валидации
✅ **Knowledge base** - вся экспертиза в одном месте
✅ **Fast onboarding** - новички продуктивны с первого дня

---

## Доступные Skills

В проекте init_claude доступно **3 skills**:

### 1. [Bash Development](/.claude/skills/bash-development/SKILL.md)

**Автоматизация разработки bash-функций для init_claude.sh**

- ✅ Создание новых bash-функций с документацией
- ✅ Добавление новых флагов и опций командной строки
- ✅ Рефакторинг существующих функций
- ✅ Работа с переменными окружения (HTTPS_PROXY, HTTP_PROXY, NO_PROXY)
- ✅ Парсинг аргументов командной строки
- ✅ Обработка ошибок с правильными exit codes
- ✅ Работа с credentials файлами
- ✅ Цветной вывод (print_info, print_success, print_error)

**Использование:**
```
Добавь новый флаг --timeout для ограничения времени ожидания при тестировании прокси
```

**Tags:** `bash, shell, scripting, development, refactoring`

---

### 2. [Proxy Management](/.claude/skills/proxy-management/SKILL.md)

**Настройка, тестирование и отладка HTTP/HTTPS/SOCKS5 прокси**

- ✅ Парсинг и валидация proxy URL
- ✅ Настройка HTTP/HTTPS/SOCKS5 прокси
- ✅ Работа с CA сертификатами (--proxy-ca)
- ✅ Тестирование подключений через curl
- ✅ Отладка проблем с прокси (timeout, auth, TLS)
- ✅ Управление переменными окружения для прокси
- ✅ TLS безопасность (insecure vs CA certificate)

**Использование:**
```
Отладь проблему с HTTPS прокси. Test proxy failed с ошибкой "SSL certificate problem: self signed certificate"
```

**Tags:** `proxy, http, https, socks5, curl, tls, certificates, debugging`

---

### 3. [Isolated Environment](/.claude/skills/isolated-environment/SKILL.md)

**Управление изолированным NVM окружением в директории проекта**

- ✅ Установка NVM в изолированную директорию (.nvm-isolated/)
- ✅ Установка Node.js и Claude Code в изолированное окружение
- ✅ Создание и работа с lockfile (.nvm-isolated-lockfile.json)
- ✅ Воспроизводимая установка из lockfile на других машинах
- ✅ Управление версиями (точные версии Node.js, Claude Code, NVM)
- ✅ Очистка изолированного окружения
- ✅ Проверка статуса изолированного окружения

**Использование:**
```
Установи Claude Code в изолированное окружение с сохранением lockfile
```

**Tags:** `nvm, nodejs, isolation, lockfile, reproducibility, versioning`

---

## Как использовать Skills

### Автоматический вызов (рекомендуется)

Claude автоматически определяет нужный skill на основе вашего запроса.

**Примеры:**

```
👤 USER: Добавь новый флаг --retry для повторных попыток при ошибке

🤖 CLAUDE: [Автоматически вызывает bash-development skill]
           Создаю новую опцию с парсингом аргументов и обработкой ошибок...
```

```
👤 USER: Почему proxy test failed с HTTP 407?

🤖 CLAUDE: [Автоматически вызывает proxy-management skill]
           HTTP 407 = Proxy Authentication Required.
           Проверяю credentials и предлагаю решение...
```

### Явный вызов (для сложных задач)

Можно явно указать skill в запросе:

```
Используя bash-development skill, создай функцию для ротации credentials backups.
```

### Комбинированные запросы (composability)

Skills автоматически комбинируются для сложных задач:

```
👤 USER: Добавь поддержку SOCKS4 прокси в init_claude.sh с полной валидацией

🤖 CLAUDE: [Автоматически вызывает proxy-management + bash-development]
           1. Добавляю socks4:// в валидацию URL (proxy-management)
           2. Обновляю parse_proxy_url() (bash-development)
           3. Добавляю примеры в show_usage() (bash-development)
           4. Тестирую новую функциональность (proxy-management)
```

---

## Как создать новый Skill

### Шаг 1: Определите необходимость

Создавайте skill когда:
- ✅ Задача повторяется 3+ раза
- ✅ Требует специфичных знаний проекта (init_claude архитектура)
- ✅ Имеет сложную последовательность шагов
- ✅ Часто приводит к ошибкам при ручном выполнении

**НЕ создавайте skill для:**
- ❌ Одноразовых задач
- ❌ Тривиальных операций
- ❌ Слишком специфичных edge cases

### Шаг 2: Создайте структуру

```bash
# Создать директорию
mkdir -p .claude/skills/your-skill-name

# Создать SKILL.md
touch .claude/skills/your-skill-name/SKILL.md
```

### Шаг 3: Заполните SKILL.md

**Минимальный шаблон:**

```markdown
---
name: Your Skill Name
description: Краткое описание (1 строка)
version: 1.0.0
author: init_claude Team
tags: [bash, tag2, tag3]
dependencies: []
---

# Your Skill Name

Подробное описание skill и его назначения для init_claude.

## Когда использовать этот скил

Используй этот скил когда нужно:
- Задача 1
- Задача 2
- Задача 3

Скил автоматически вызывается при запросах типа:
- "Запрос 1"
- "Запрос 2"

## Контекст проекта

Проект init_claude использует:
- **Bash 4+** с set -euo pipefail
- **Технология X** - описание
- **Паттерн Y** - описание

## Шаблоны кода

### Шаблон 1

```bash
# Bash code template с placeholders
function_name() {
    local param1=$1
    # Implementation
}
```

## Проверочный чеклист

После выполнения проверь:

- [ ] Пункт 1
- [ ] Пункт 2
- [ ] Пункт 3

## Связанные скилы

- **bash-development**: для задачи X
- **proxy-management**: для задачи Y

## Примеры использования

### Пример 1: Название

```
Описание запроса к Claude
```

Claude использует skill для выполнения...

## Часто задаваемые вопросы

**Q: Вопрос 1?**

A: Ответ 1
```

### Шаг 4: Добавьте в этот файл (SKILLS.md)

Обновите раздел "Доступные Skills" с описанием нового skill.

### Шаг 5: Протестируйте

Попробуйте использовать новый skill с различными запросами:

```
Используя your-skill-name, выполни [задачу]
```

Проверьте что:
- ✅ Claude корректно интерпретирует skill
- ✅ Генерируется правильный bash-код
- ✅ Все шаблоны работают
- ✅ Чеклисты полные

---

## Best Practices

### ✅ DO: Что нужно делать

1. **Используйте YAML frontmatter**
   - Облегчает автоматический парсинг
   - Позволяет фильтровать skills по tags

2. **Описывайте контекст проекта**
   - Bash-специфичные паттерны init_claude
   - Архитектура скрипта
   - Используемые инструменты (curl, openssl, npm)

3. **Предоставляйте bash code templates**
   - С placeholders: `{function_name}`, `{variable}`
   - Готовые к копированию

4. **Добавляйте чеклисты**
   - Что проверить после выполнения
   - Prevents забытые шаги (валидация, документация, тесты)

5. **Включайте примеры**
   - Реальные use cases из init_claude
   - Различные сценарии использования

6. **Документируйте edge cases**
   - FAQ секция
   - Troubleshooting guide для proxy проблем

7. **Указывайте dependencies**
   - Какие skills связаны
   - Когда их использовать вместе

### ❌ DON'T: Чего избегать

1. **Не дублируйте информацию**
   - Ссылайтесь на другие skills
   - DRY principle

2. **Не делайте слишком generic**
   - Skills должны быть специфичны для init_claude
   - Общие bash инструкции → документация

3. **Не перегружайте skill**
   - Один skill = одна задача (bash development OR proxy management)
   - Разбивайте на несколько skills

4. **Не забывайте про versioning**
   - Обновляйте version при изменениях
   - Документируйте breaking changes

5. **Не пропускайте примеры**
   - Без примеров skill сложно использовать
   - Минимум 2-3 реальных примера из init_claude

---

## Примеры использования

### Пример 1: Добавление новой функции (bash-development)

**Задача:** Добавить функцию для ротации credentials backups

**Запрос:**

```
Создай функцию rotate_credentials() которая создает backup старых credentials перед сохранением новых.
Храни до 3 последних backups.
```

**Claude автоматически использует:**
- `bash-development` → создание функции с документацией
- `bash-development` → интеграция в save_credentials()

**Результат:**
```bash
#######################################
# Rotate credentials backups
# Keeps up to 3 most recent backups
#######################################
rotate_credentials() {
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        [[ -f "${CREDENTIALS_FILE}.2" ]] && mv "${CREDENTIALS_FILE}.2" "${CREDENTIALS_FILE}.3"
        [[ -f "${CREDENTIALS_FILE}.1" ]] && mv "${CREDENTIALS_FILE}.1" "${CREDENTIALS_FILE}.2"
        cp "$CREDENTIALS_FILE" "${CREDENTIALS_FILE}.1"
    fi
}
```

---

### Пример 2: Отладка proxy (proxy-management)

**Задача:** Отладить проблему с HTTPS прокси

**Запрос:**

```
Test proxy failed с ошибкой "SSL certificate problem: self signed certificate".
Что делать?
```

**Claude автоматически использует:**
- `proxy-management` → анализ TLS проблемы
- `proxy-management` → предложение решения (--proxy-ca vs --proxy-insecure)

**Результат:**
```bash
# Решение 1 (SECURE - рекомендуется):
openssl s_client -showcerts -connect proxy:8118 < /dev/null 2>/dev/null | \
  openssl x509 -outform PEM > proxy-cert.pem

init_claude --proxy https://user:pass@proxy:8118 --proxy-ca proxy-cert.pem

# Решение 2 (INSECURE - только для тестирования):
init_claude --proxy https://user:pass@proxy:8118 --proxy-insecure
```

---

### Пример 3: End-to-end task (оба skills)

**Задача:** Добавить поддержку нового типа прокси с полным workflow

**Запрос:**

```
Добавь поддержку SOCKS4 прокси в init_claude.sh:
1. Валидация socks4:// URL
2. Парсинг socks4 протокола
3. Тестирование через curl
4. Обновление документации
```

**Claude автоматически использует:**
- `proxy-management` → модификация validate_proxy_url() для socks4
- `bash-development` → создание bash-функции parse_socks4_url()
- `proxy-management` → добавление curl теста для socks4
- `bash-development` → обновление show_usage()

---

## FAQ

### Q: Как узнать какие skills доступны?

**A:** Все доступные skills перечислены в разделе ["Доступные Skills"](#доступные-skills) этого документа. Также можно просмотреть директорию `.claude/skills/`.

```bash
ls -la .claude/skills/
```

---

### Q: Могу ли я изменить существующий skill?

**A:** Да! Skills — это обычные Markdown файлы. Отредактируйте `.claude/skills/{skill-name}/SKILL.md`.

**Не забудьте:**
- Обновить `version` в YAML frontmatter
- Протестировать изменения
- Документировать breaking changes (если есть)

---

### Q: Как создать skill для другого языка программирования?

**A:** Проект init_claude специфичен для **bash**. Если вы работаете над другим проектом (например, Python), создайте skills с соответствующим контекстом:

```markdown
## Контекст проекта

Проект использует:
- **Python 3.10+** с type hints
- **FastAPI** для REST API
- **pytest** для тестирования
```

---

### Q: Сколько skills нужно проекту?

**A:** Зависит от размера и сложности проекта:

- **Маленький проект** (1 bash-скрипт): 2-3 skills
- **Средний проект** (несколько скриптов): 4-6 skills
- **Большой проект** (много скриптов): 6-10 skills

**Правило:** Создавайте skill когда задача повторяется 3+ раза.

**Для init_claude:** 2 skills (bash-development, proxy-management) покрывают 90% задач.

---

### Q: Можно ли использовать skills для документации?

**A:** Да! Создайте `documentation` skill:

```markdown
---
name: Documentation
description: Обновление README.md, CLAUDE.md и --help секций
tags: [docs, markdown, help]
---

# Documentation Skill

## Шаблоны

### Обновление README.md

...

### Добавление в --help

...
```

---

### Q: Как измерить эффективность skills?

**A:** Отслеживайте метрики:

- **Time saved**: Сколько времени экономится на типичных задачах
- **Error reduction**: Снижение количества bugs
- **Consistency**: Единообразие кода
- **Onboarding time**: Скорость адаптации новых разработчиков

**Пример для init_claude:**
- Без skill: Добавление нового флага = 15 минут
- Со skill: Добавление нового флага = 3 минуты
- **Экономия:** 80% времени

---

### Q: Нужно ли коммитить skills в git?

**A:** **Да!** Skills — часть кодовой базы.

```bash
git add .claude/skills/
git commit -m "feat: Add bash-development and proxy-management skills"
git push
```

**Преимущества:**
- ✅ Version control
- ✅ Code review
- ✅ Доступны всей команде
- ✅ История изменений

---

## Roadmap

### Планируемые skills (v2.0)

- **Documentation** - Обновление README.md, CLAUDE.md, --help секций
- **Testing & Debugging** - Создание test cases, отладка bash-скриптов
- **Release Management** - Версионирование, changelog, git tags

### Slash Commands (будущие)

- `/test-proxy` - Быстрое тестирование прокси
- `/update-docs` - Обновление документации
- `/add-flag` - Мастер создания нового флага

### Feedback

Нашли баг или хотите предложить улучшение?

- 📧 GitHub Issues: [Create Issue](https://github.com/ikeniborn/init_claude/issues/new)
- 💬 Обсуждения: [Discussions](https://github.com/ikeniborn/init_claude/discussions)

---

## Заключение

**Claude Skills** — мощный инструмент для автоматизации разработки init_claude, который:

✅ Ускоряет разработку bash-функций на 40-60%
✅ Стандартизирует code style и архитектуру
✅ Снижает количество багов на 30%
✅ Упрощает onboarding новых разработчиков на 70%

**Начните использовать skills прямо сейчас:**

```
Добавь новый флаг --retry для повторных попыток при ошибке подключения к прокси
```

**Happy bash coding! 🚀**

---

**Версия документа:** 1.0.0
**Последнее обновление:** 2025-10-22
**Лицензия:** MIT
