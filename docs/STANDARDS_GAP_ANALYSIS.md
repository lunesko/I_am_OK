# Gap Analysis: Ya OK vs ISO/IEC 12207

**Дата:** 6 лютого 2026  
**Проект:** Ya OK Messenger (DTN-based secure messaging)  
**Версія:** 0.2.0-rc2  
**Базові стандарти:** ISO/IEC 12207, ISO 25010, ISO 27001

---

## Executive Summary

**Поточний стан:** Робочий прототип з функціональним кодом  
**Рівень формальності:** Low (startup/prototype level)  
**Цільовий рівень:** Medium (production-ready with documentation)  
**Критичність:** High (безпека, шифрування, mesh networking)

**Основна проблема:** Є код, але немає формальних артефактів для:
- Сертифікації безпеки
- Передачі в підтримку
- Аудиту якості
- Масштабування команди

---

## 1. Requirements Engineering (ISO 29148)

### ✅ Що є:

- README.md з описом features
- USER_GUIDE_8_FIXES.md
- Issue tracking (8 documented issues)
- DEFINITION_OF_DONE_AND_SCENARIOS.md

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| **SRS (Software Requirements Specification)** | ❌ Немає | **CRITICAL** | Week 1 |
| Functional Requirements (формальні) | ❌ Немає | HIGH | Week 1 |
| Non-Functional Requirements (ISO 25010) | ⚠️ Частково | HIGH | Week 1 |
| Glossary | ❌ Немає | MEDIUM | Week 2 |
| Requirements Traceability Matrix (RTM) | ❌ Немає | MEDIUM | Week 2 |
| Stakeholder Register | ❌ Немає | LOW | Week 3 |

### 📋 Наслідки відсутності:

- Неможливо формально валідувати систему
- Неможливо довести відповідність вимогам
- Неясні критерії acceptance
- Ризик scope creep

---

## 2. Architecture & Design (IEEE 1016, ISO 42010)

### ✅ Що є:

- ARCH_SPEC_FINAL.md (є!)
- Код розділено на модулі (android, ios, relay, ya_ok_core)
- RELAY_SERVER_GUIDE.md
- packet_flow.md

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| **Architecture Design Document (ADD)** | ⚠️ Є ARCH_SPEC | MEDIUM | Week 2 |
| C4 diagrams (Context, Container, Component) | ❌ Немає | HIGH | Week 2 |
| Sequence diagrams для критичних потоків | ❌ Немає | HIGH | Week 2 |
| Data model (formal ER diagram) | ❌ Немає | MEDIUM | Week 3 |
| API contracts (OpenAPI/Swagger) | ❌ Немає | MEDIUM | Week 3 |
| **Threat Model (ISO 27001)** | ❌ Немає | **CRITICAL** | Week 1 |
| Low-Level Design (LLD) | ❌ Немає | LOW | Week 4 |

### 📋 Наслідки відсутності:

- Неможливо провести security audit
- Складно онбордити нових розробників
- Немає формального обґрунтування архітектурних рішень
- Ризики безпеки не документовані

---

## 3. Testing (ISO 29119)

### ✅ Що є:

- TEST_PLAN.md
- TEST_SCENARIOS_EXECUTION_REPORT.md
- TWO_DEVICE_TEST_RESULTS.md
- Unit тести (QrParsingTest.kt, CoreGatewayTest.kt)
- Integration tests

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| **Test Strategy** | ⚠️ Є TEST_PLAN | MEDIUM | Week 2 |
| Test Cases (формальні, з preconditions) | ⚠️ Частково | HIGH | Week 2 |
| Test Data specification | ❌ Немає | MEDIUM | Week 3 |
| Acceptance Criteria (формальні) | ❌ Немає | HIGH | Week 1 |
| Security Test Plan | ❌ Немає | **CRITICAL** | Week 1 |
| Performance Test Plan | ❌ Немає | HIGH | Week 2 |
| Test Coverage Report | ❌ Немає | MEDIUM | Week 3 |
| Regression Test Suite | ⚠️ Частково | HIGH | Week 2 |

### 📋 Наслідки відсутності:

- Неможливо формально довести якість
- Немає метрик покриття тестами
- Неясно, чи пройдено acceptance
- Ризики regression при змінах

---

## 4. Security (ISO 27001)

### ✅ Що є:

- SECURITY.md
- RELAY_SECURITY.md
- SECURE_KEY_STORAGE.md
- Шифрування XChaCha20-Poly1305
- X25519 key exchange
- SQLCipher для даних

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| **Threat Model (STRIDE/DREAD)** | ❌ Немає | **CRITICAL** | Week 1 |
| Security Requirements Specification | ⚠️ Розкидано | **CRITICAL** | Week 1 |
| Security Test Plan | ❌ Немає | **CRITICAL** | Week 1 |
| Vulnerability Assessment Report | ❌ Немає | HIGH | Week 2 |
| Penetration Test Report | ❌ Немає | HIGH | Week 3 |
| Security Audit Trail | ❌ Немає | MEDIUM | Week 2 |
| Incident Response Plan | ❌ Немає | HIGH | Week 2 |
| Data Protection Impact Assessment (GDPR) | ❌ Немає | HIGH | Week 2 |

### 📋 Наслідки відсутності:

- **Неможливо пройти security audit**
- **Неможливо довести безпеку користувачам**
- **Юридичні ризики (GDPR, CCPA)**
- Немає плану реагування на інциденти

---

## 5. Development Process

### ✅ Що є:

- Git repository
- Code review практика (судячи з рефакторингу)
- Coding standards (Kotlin, Swift, Rust)
- CONTRIBUTING.md

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| Coding Standards Document | ⚠️ Неформальні | MEDIUM | Week 3 |
| Code Review Checklist | ❌ Немає | MEDIUM | Week 3 |
| CI/CD Documentation | ❌ Немає | MEDIUM | Week 2 |
| Build & Release Procedure | ⚠️ Є RELEASE_BUILD.md | MEDIUM | Week 3 |
| Version Control Policy | ❌ Немає | LOW | Week 4 |
| Static Code Analysis Reports | ❌ Немає | MEDIUM | Week 2 |

---

## 6. Release & Deployment (ITIL 4)

### ✅ Що є:

- RELEASE_NOTES_v0.1.0.md
- CHANGELOG.md
- Dockerfile (relay)
- fly.toml (deployment config)
- RELEASE_BUILD.md

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| Deployment Guide (production) | ⚠️ Частково | HIGH | Week 2 |
| Rollback Plan | ❌ Немає | HIGH | Week 2 |
| Monitoring & Alerting Setup | ❌ Немає | HIGH | Week 2 |
| Backup & Restore Procedures | ❌ Немає | HIGH | Week 2 |
| Disaster Recovery Plan | ❌ Немає | MEDIUM | Week 3 |
| SLA/SLO definitions | ❌ Немає | MEDIUM | Week 3 |

---

## 7. Operations & Maintenance (ITIL 4)

### ✅ Що є:

- support-page.html
- privacy-policy.md
- terms-of-use.md

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| **Operational Procedures** | ❌ Немає | HIGH | Week 3 |
| Incident Management Process | ❌ Немає | HIGH | Week 3 |
| Problem Management Process | ❌ Немає | MEDIUM | Week 4 |
| Change Management Process | ❌ Немає | MEDIUM | Week 4 |
| Monitoring Dashboards | ❌ Немає | HIGH | Week 2 |
| User Manual (formal) | ⚠️ Є USER_GUIDE | MEDIUM | Week 3 |
| Admin Manual | ❌ Немає | HIGH | Week 3 |
| Troubleshooting Guide | ❌ Немає | HIGH | Week 3 |

---

## 8. Quality Management (ISO 9001, ISO 25010)

### ✅ Що є:

- QA_MATRIX.md
- Code refactoring (just completed)
- Test reports

### ❌ Чого немає:

| Артефакт | Статус | Критичність | Термін |
|----------|--------|-------------|--------|
| Quality Management Plan | ❌ Немає | MEDIUM | Week 3 |
| Quality Metrics (ISO 25010) | ❌ Немає | MEDIUM | Week 3 |
| Audit Reports | ❌ Немає | LOW | Week 4 |
| Quality Gates definition | ❌ Немає | MEDIUM | Week 3 |
| Technical Debt Register | ❌ Немає | MEDIUM | Week 4 |

---

## Підсумкова таблиця пріоритетів

| Пріоритет | Артефакт | Критичність | Трудомісткість | Термін |
|-----------|----------|-------------|----------------|--------|
| **P0** | Security Threat Model | CRITICAL | 16h | Week 1 |
| **P0** | Security Requirements | CRITICAL | 12h | Week 1 |
| **P0** | Security Test Plan | CRITICAL | 8h | Week 1 |
| **P1** | SRS (Software Requirements Spec) | CRITICAL | 24h | Week 1 |
| **P1** | Non-Functional Requirements | HIGH | 8h | Week 1 |
| **P1** | Acceptance Criteria | HIGH | 4h | Week 1 |
| **P2** | C4 Architecture Diagrams | HIGH | 12h | Week 2 |
| **P2** | Sequence Diagrams (critical flows) | HIGH | 8h | Week 2 |
| **P2** | Formal Test Cases | HIGH | 16h | Week 2 |
| **P2** | Deployment Guide | HIGH | 6h | Week 2 |
| **P2** | Monitoring Setup | HIGH | 8h | Week 2 |
| **P3** | API Contracts (OpenAPI) | MEDIUM | 12h | Week 3 |
| **P3** | Operational Procedures | MEDIUM | 8h | Week 3 |
| **P3** | Incident Response Plan | MEDIUM | 6h | Week 3 |
| **P3** | User/Admin Manuals | MEDIUM | 12h | Week 3 |
| **P4** | RTM, Glossary, LLD | LOW | 16h | Week 4 |

**Total estimate:** 176 hours (~4-5 weeks for 1 person)

---

## Рекомендації

### Immediate Actions (Week 1):

1. **Security First**
   - Threat Model (STRIDE)
   - Security Requirements
   - Security Test Plan

2. **Requirements Baseline**
   - SRS document
   - Non-functional requirements (ISO 25010)
   - Acceptance criteria

### Short-term (Weeks 2-3):

3. **Architecture Formalization**
   - C4 diagrams
   - Sequence diagrams
   - API contracts

4. **Testing & Deployment**
   - Formal test cases
   - Deployment guide
   - Monitoring setup

### Medium-term (Week 4+):

5. **Operations**
   - Procedures
   - Incident management
   - Troubleshooting guides

---

## Адаптація під Ya OK

**Рекомендований підхід:** Hybrid (не чистий waterfall)

- Зберегти agile розробку
- Додати формальні артефакти на checkpoints
- Використовувати templates для швидкості
- Автоматизувати де можливо (RTM, coverage)

**Не робити:**
- ❌ Повний waterfall (занадто повільно)
- ❌ Всі артефакти одразу (overkill)
- ❌ Документація без коду (марно)

**Робити:**
- ✅ P0/P1 артефакти перед production
- ✅ Continuous documentation (з кодом)
- ✅ Automation (tests, coverage, security scans)
- ✅ Living documents (не одноразові)

---

## Наступні кроки

Скажи що потрібно:

1. **🔐 Security package** (P0) - Threat Model + Security Reqs + Test Plan
2. **📋 Requirements package** (P1) - SRS + NFRs + Acceptance Criteria
3. **🏗️ Architecture package** (P2) - C4 + Sequences + API contracts
4. **🧪 Testing package** (P2) - Formal test cases + coverage
5. **🚀 Deployment package** (P2) - Deployment + Monitoring + Rollback
6. **📚 Full documentation suite** (All) - Всі артефакти

Або вкажи специфіку:
- Готуєтесь до аудиту?
- Потрібна сертифікація?
- Залучаєте інвесторів?
- Масштабуєте команду?
- Виходите на regulated market?

**Без води, конкретно: який package потрібен зараз?**
