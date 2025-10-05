# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a utility tool for launching Claude Code through HTTP/SOCKS5 proxies with automatic credential management. The project consists of a single bash script that can be installed globally.

## Architecture

The codebase is a standalone bash script (`init_claude.sh`) that:

1. **Credential Management**: Stores proxy credentials in `.claude_proxy_credentials` (chmod 600, git-ignored)
2. **Proxy Configuration**: Sets environment variables (HTTPS_PROXY, HTTP_PROXY, NO_PROXY) for Claude Code
3. **Global Installation**: Creates symlink at `/usr/local/bin/init_claude` for system-wide access
4. **Proxy Detection**: Prioritizes global Claude Code installation over local installations

### Key Components

- **Proxy URL Parsing** (lines 66-103): Extracts protocol, username, password, host, port from URLs
- **Credential Persistence** (lines 108-145): Saves/loads proxy settings from `.claude_proxy_credentials`
- **Proxy Testing** (lines 248-258): Validates connectivity via curl before launching
- **Dependency Installation** (lines 283-387): Auto-installs Node.js, npm, and Claude Code if missing
- **Claude Detection** (lines 454-500): Finds global Claude Code binary, avoiding local npm installations

## Common Commands

### Installation
```bash
# Install globally (creates /usr/local/bin/init_claude)
# Automatically checks and installs dependencies:
# - Node.js and npm (if missing)
# - Claude Code (if missing)
sudo ./init_claude.sh --install

# Uninstall
sudo init_claude --uninstall
```

### Usage
```bash
# Launch with saved credentials (interactive prompt if none exist)
init_claude

# Set proxy directly
init_claude --proxy http://user:pass@host:port

# Test proxy without launching Claude
init_claude --test

# Clear saved credentials
init_claude --clear

# Skip connectivity test
init_claude --no-test

# Pass arguments to Claude Code
init_claude -- --model claude-3-opus

# Skip permission checks (use with caution)
init_claude --dangerously-skip-permissions
```

## Development Notes

### Proxy URL Format
Supported formats: `http://`, `https://`, `socks5://`

Pattern: `protocol://[username:password@]host:port`

Examples:
- `http://alice:secret@127.0.0.1:8118`
- `socks5://user:pass@proxy.example.com:1080`

### Security Considerations
- Credentials file has 600 permissions (owner read/write only)
- Passwords are masked in output by default (use `--show-password` to reveal)
- The credentials file is automatically excluded from git

### Script Behavior
- Uses `set -euo pipefail` for strict error handling
- Follows symlinks to resolve the script's actual directory
- Prioritizes global Claude Code installations (`/usr/local/bin/claude`, `/usr/bin/claude`) over local `node_modules`
- Warns if local Claude installation detected and attempts to find global installation

### Dependency Installation
During `--install`, the script automatically checks and installs missing dependencies:

1. **Node.js and npm** (if missing):
   - Uses NodeSource official repository (Node.js 18 LTS)
   - Command: `curl -fsSL https://deb.nodesource.com/setup_18.x | bash -`
   - Then: `apt-get install -y nodejs`
   - Prompts for confirmation before installing

2. **Claude Code** (if missing):
   - Installs globally via npm
   - Command: `npm install -g @anthropic-ai/claude-code`
   - Prompts for confirmation before installing

3. **Installation Flow**:
   - Checks npm → if missing, offers to install Node.js
   - Checks Claude Code → if missing, offers to install
   - Only proceeds with script installation if dependencies are satisfied
   - Can skip dependency installation but warns about missing requirements

### Git and Proxy Considerations

**Important:** Git push/pull through HTTP proxy may not work due to HTTPS CONNECT limitations.

**Issue:**
- The HTTP proxy works fine for Claude Code and curl
- However, `git push` fails with error: `Proxy CONNECT aborted`
- This is a known limitation of some HTTP proxies that don't support HTTPS CONNECT for git

**Workaround for git operations:**

```bash
# Temporarily disable proxy for git push/pull
unset HTTPS_PROXY HTTP_PROXY NO_PROXY
git push origin master
git pull origin master

# Or use SSH instead of HTTPS for git remote
git remote set-url origin git@github.com:username/repo.git
git push origin master
```

**Credentials file:**
The proxy credentials are stored in `.claude_proxy_credentials` and are only used by the `init_claude` script. They don't affect global git operations unless you manually export the environment variables.

### Testing
No automated tests exist. Test manually:
```bash
# Test proxy connectivity
init_claude --test

# Test full flow
init_claude --proxy http://test:test@127.0.0.1:8118 --no-test
```
# PART I: UNIVERSAL WORKFLOW EXECUTION RULES

## 1. CRITICAL PRINCIPLES (P1-P5)

### P1: Sequential Execution (CRITICAL)
**Правило:** Выполняйте фазы и actions СТРОГО последовательно.

**Обязательно:**
- ✓ Выполняйте фазы в указанном порядке
- ✓ Выполняйте все actions внутри фазы по порядку
- ✓ НЕ пропускайте фазы
- ✓ НЕ пропускайте actions
- ✓ НЕ меняйте порядок выполнения

**Нарушение:** FATAL - немедленная остановка

---

### P2: Thinking Requirement (CRITICAL)
**Правило:** ОБЯЗАТЕЛЬНО используйте `<thinking>` перед критическими решениями.

**Когда обязателен thinking:**
- Перед началом каждой фазы
- Перед actions помеченными `requires_thinking="true"`
- Перед actions с `validation="critical"`
- Перед принятием важных технических решений
- При выборе между альтернативными подходами

**Что должен содержать thinking:**
- Анализ текущей ситуации
- Оценка рисков
- Обоснование выбранного решения
- Рассмотрение альтернатив
- План проверки результата

**Формат thinking:**
```xml
<thinking>
1. АНАЛИЗ: [что имеем]
2. ОПЦИИ: [какие варианты]
3. ВЫБОР: [что выбираем и почему]
4. РИСКИ: [что может пойти не так]
5. ВАЛИДАЦИЯ: [как проверим]
</thinking>
```

**Нарушение:** FATAL - действие НЕ ВЫПОЛНЯЕТСЯ без thinking

---

### P3: Mandatory Output Enforcement (CRITICAL)
**Правило:** Выводите ВСЕ обязательные outputs в указанных форматах.

**Когда output обязателен:**
- Action помечен `output="required"`
- Action имеет `mandatory_output` секцию
- Action имеет `mandatory_format` секцию
- Checkpoint требует verification_instruction

**Обязательно:**
- ✓ Используйте ТОЧНО указанный формат
- ✓ Заполните ВСЕ секции mandatory_format
- ✓ НЕ сокращайте форматы
- ✓ НЕ пропускайте секции
- ✓ НЕ заменяйте формат на "свой"

**Нарушение:** BLOCKING - нельзя продолжить без output

---

### P4: Exit Conditions Verification (CRITICAL)
**Правило:** Проверяйте exit_conditions перед продолжением.

**Обязательно:**
- ✓ Проверьте ВСЕ conditions в exit_conditions
- ✓ НЕ продолжайте если хотя бы одно condition не выполнено
- ✓ Выведите статус каждого condition явно
- ✓ При невыполнении - выполните violation_action

**Типичные exit_conditions:**
- Все обязательные actions выполнены
- Все mandatory_outputs выведены
- Validation passed
- Checkpoint пройден

**Нарушение:** FATAL - блокировка перехода к следующему шагу

---

### P5: Checkpoint Verification (HIGH)
**Правило:** Проходите checkpoints с явной верификацией перед переходом между фазами.

**Обязательно:**
- ✓ Проверьте ВСЕ checks в checkpoint
- ✓ Выведите verification_instruction если указана
- ✓ НЕ переходите к следующей фазе пока ВСЕ checks != ✓
- ✓ Выводите статус checkpoint явно

**Формат checkpoint verification:**
```
PHASE N CHECKPOINT:
[✓/✗] Check 1: [статус и детали]
[✓/✗] Check 2: [статус и детали]
[✓/✗] Check N: [статус и детали]

РЕЗУЛЬТАТ: ✓ PASSED / ✗ FAILED
Переход к Phase N+1: [ALLOWED/BLOCKED]
```

**Нарушение:** BLOCKING - нельзя перейти к следующей фазе

---

## 2. HIGH-PRIORITY RULES (P6-P10)

### P6: Entry Conditions Check (HIGH)
**Правило:** Проверяйте entry_conditions перед входом в фазу.

**Обязательно:**
- ✓ Проверьте все entry conditions
- ✓ При невыполнении - выполните violation_action
- ✓ НЕ начинайте фазу без выполнения conditions

---

### P7: Blocking Actions Enforcement (HIGH)
**Правило:** Для actions с `blocking="true"` - строго следуйте ограничениям.

**Обязательно:**
- ✓ Завершите action полностью
- ✓ Выведите mandatory_output
- ✓ Проверьте exit_condition
- ✓ НЕ продолжайте до выполнения всех требований

---

### P8: Validation Level Respect (HIGH)
**Правило:** Выполняйте validation в соответствии с уровнем.

**Уровни validation:**
- `critical`: ОБЯЗАТЕЛЬНАЯ проверка, STOP при failure
- `standard`: Обычная проверка, retry при failure
- `micro`: Быстрая проверка, log при failure

**Для validation="critical":**
- ОБЯЗАТЕЛЬНО thinking перед action
- ОБЯЗАТЕЛЬНО вывод результата проверки
- STOP немедленно при failure
- НЕ продолжать до исправления

---

### P9: Error Handling Compliance (HIGH)
**Правило:** Следуйте error_handling правилам при ошибках.

**Обязательно:**
- ✓ Определите тип ошибки
- ✓ Выполните указанный action (STOP/RETRY/ASK)
- ✓ Выведите указанное error message
- ✓ НЕ игнорируйте ошибки
- ✓ НЕ продолжайте при STOP errors

---

### P10: Approval Gates Respect (HIGH)
**Правило:** Для approval_gate с `required="true"` - ждите подтверждения.

**Обязательно:**
- ✓ Выведите approval gate message
- ✓ ЖДИТЕ подтверждения пользователя
- ✓ НЕ продолжайте автоматически
- ✓ Предложите опции (yes/no/review)

---

## 3. MEDIUM-PRIORITY RULES (P11-P13)

### P11: Ask When Unclear (MEDIUM)
**Правило:** При неясности - ОСТАНОВИТЕСЬ и спросите.

**Когда спрашивать:**
- Требования неоднозначны
- Несколько возможных интерпретаций
- Отсутствует критичная информация
- Неясен ожидаемый результат

**Формат вопроса:**
```
❓ ТРЕБУЕТСЯ УТОЧНЕНИЕ
Неясно: [что конкретно]
Варианты: [опции]
Вопрос: [конкретный вопрос]
```

---

### P12: Decision Documentation (MEDIUM)
**Правило:** Документируйте важные технические решения.

**Что документировать:**
- Выбор между альтернативными подходами
- Отклонение очевидных вариантов
- Trade-offs и компромиссы

---

### P13: Conditional Execution (MEDIUM)
**Правило:** Выполняйте conditional actions только при выполнении condition.

---

## 4. PROHIBITED & MANDATORY ACTIONS

### НИКОГДА НЕ ДЕЛАЙТЕ:
❌ НЕ пропускайте фазы / actions / thinking / mandatory_output
❌ НЕ сокращайте форматы
❌ НЕ продолжайте при critical failures
❌ НЕ игнорируйте blocking conditions / exit_conditions / checkpoints
❌ НЕ делайте assumptions - ASK при неясности

### ВСЕГДА ДЕЛАЙТЕ:
✓ ВСЕГДА используйте thinking для requires_thinking="true"
✓ ВСЕГДА выводите mandatory_output для output="required"
✓ ВСЕГДА проверяйте exit_conditions / checkpoints / conditions
✓ ВСЕГДА останавливайтесь при critical failures
✓ ВСЕГДА спрашивайте при неясности
✓ ВСЕГДА выполняйте последовательно
✓ ВСЕГДА обрабатывайте ошибки

---

## 5. STANDARD FORMATS

### Формат Thinking:
```xml
<thinking>
КОНТЕКСТ: [текущая ситуация]
ЗАДАЧА: [что нужно сделать]
ОПЦИИ: [варианты с плюсами/минусами]
ВЫБОР: [вариант N] потому что [обоснование]
РИСКИ: [что может пойти не так]
ПРОВЕРКА: [как валидируем результат]
</thinking>
```

### Формат Error Message:
```
[ICON] ОШИБКА: [Тип]
Проблема: [описание]
Контекст: [где произошло]
Действие: [STOP/RETRY/ASK]
```

### Формат Checkpoint:
```
PHASE N CHECKPOINT:
[✓/✗] Check 1: [детали]
РЕЗУЛЬТАТ: ✓ PASSED / ✗ FAILED
Переход: [ALLOWED/BLOCKED]
```

---