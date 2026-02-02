# CI/CD Pipeline Setup для Ya OK

## Обзор архитектуры

```
┌─────────────────┐
│   GitHub Repo   │
│    (main)       │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│          GitHub Actions CI/CD                │
│                                              │
│  Build → Dev → Staging → Production         │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│              Azure Resources                 │
│                                              │
│  ┌──────────────┐  ┌──────────────┐         │
│  │ Container    │  │  App Service │         │
│  │ Apps (Relay) │  │  (Static)    │         │
│  └──────────────┘  └──────────────┘         │
│           ▲              ▲                   │
│           └──────┬───────┘                   │
│                  │                           │
│          ┌───────────────┐                   │
│          │      ACR      │                   │
│          └───────────────┘                   │
└─────────────────────────────────────────────┘
```

## Шаг 1: Создание Azure Managed Identity

Создайте отдельную User-assigned Managed Identity для pipeline:

```bash
# Создайте resource group для pipeline infrastructure
az group create --name rg-yaok-pipeline --location westeurope

# Создайте managed identity
az identity create \
  --name yaok-github-pipeline \
  --resource-group rg-yaok-pipeline

# Получите значения для GitHub secrets
az identity show \
  --name yaok-github-pipeline \
  --resource-group rg-yaok-pipeline \
  --query '{clientId: clientId, tenantId: tenantId, subscriptionId: subscriptionId}'
```

## Шаг 2: Настройка RBAC и Federated Credentials

### 2.1 Назначьте роли для каждого окружения

```bash
# Для Dev environment
az role assignment create \
  --assignee <CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<DEV_RESOURCE_GROUP>

az role assignment create \
  --assignee <CLIENT_ID> \
  --role AcrPull \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<DEV_RESOURCE_GROUP>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>

# Повторите для Staging и Production resource groups
```

### 2.2 Создайте Federated Credentials

```bash
# Dev environment
az identity federated-credential create \
  --name yaok-github-dev \
  --identity-name yaok-github-pipeline \
  --resource-group rg-yaok-pipeline \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<YOUR_ORG>/<YOUR_REPO>:environment:dev \
  --audiences api://AzureADTokenExchange

# Staging environment
az identity federated-credential create \
  --name yaok-github-staging \
  --identity-name yaok-github-pipeline \
  --resource-group rg-yaok-pipeline \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<YOUR_ORG>/<YOUR_REPO>:environment:staging \
  --audiences api://AzureADTokenExchange

# Production environment
az identity federated-credential create \
  --name yaok-github-production \
  --identity-name yaok-github-pipeline \
  --resource-group rg-yaok-pipeline \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<YOUR_ORG>/<YOUR_REPO>:environment:production \
  --audiences api://AzureADTokenExchange
```

## Шаг 3: Настройка GitHub Environments

### 3.1 Создайте environments через GitHub UI или CLI:

```bash
# Установите GitHub CLI (если еще не установлен)
# https://cli.github.com/

# Аутентификация
gh auth login

# Создайте environments (требует browser authentication)
# Перейдите в Settings → Environments → New environment
```

Создайте три environment:
- **dev**
- **staging** (с approval rules)
- **production** (с approval rules)

### 3.2 Настройте Protection Rules

Для **staging** и **production**:
- Settings → Environments → <env> → Required reviewers
- Добавьте себя или команду для approval

## Шаг 4: Настройка GitHub Secrets и Variables

### 4.1 Repository Secrets (Settings → Secrets and variables → Actions → Secrets)

```bash
gh secret set AZURE_CLIENT_ID --body "<CLIENT_ID_FROM_STEP_1>"
gh secret set AZURE_TENANT_ID --body "<TENANT_ID_FROM_STEP_1>"
gh secret set AZURE_SUBSCRIPTION_ID --body "<SUBSCRIPTION_ID_FROM_STEP_1>"
```

### 4.2 Environment Variables для DEV

```bash
# Dev environment variables
gh variable set ACR_NAME --env dev --body "<your-acr-name>"
gh variable set RESOURCE_GROUP --env dev --body "<dev-resource-group>"
gh variable set RELAY_APP_NAME --env dev --body "<dev-relay-app-name>"
gh variable set WEB_APP_NAME --env dev --body "<dev-web-app-name>"
```

### 4.3 Environment Variables для STAGING

```bash
# Staging environment variables
gh variable set ACR_NAME --env staging --body "<your-acr-name>"
gh variable set RESOURCE_GROUP --env staging --body "<staging-resource-group>"
gh variable set RELAY_APP_NAME --env staging --body "<staging-relay-app-name>"
gh variable set WEB_APP_NAME --env staging --body "<staging-web-app-name>"
```

### 4.4 Environment Variables для PRODUCTION

```bash
# Production environment variables
gh variable set ACR_NAME --env production --body "<your-acr-name>"
gh variable set RESOURCE_GROUP --env production --body "<production-resource-group>"
gh variable set RELAY_APP_NAME --env production --body "<production-relay-app-name>"
gh variable set WEB_APP_NAME --env production --body "<production-web-app-name>"
```

## Шаг 5: Структура Azure Resources

### Рекомендуемая структура:

```
Subscription
├── rg-yaok-pipeline (pipeline infrastructure)
│   └── yaok-github-pipeline (Managed Identity)
│
├── rg-yaok-dev (development)
│   ├── ACR (shared or dev-specific)
│   ├── Container App (relay-dev)
│   └── App Service (web-dev)
│
├── rg-yaok-staging (staging)
│   ├── Container App (relay-staging)
│   └── App Service (web-staging)
│
└── rg-yaok-prod (production)
    ├── Container App (relay-prod)
    └── App Service (web-prod)
```

## Шаг 6: Проверка и запуск

1. Закоммитьте изменения в ветку `main`
2. Pipeline запустится автоматически
3. Dev деплоится автоматически
4. Staging и Production требуют manual approval

### Мониторинг деплоя:

```bash
# Проверьте статус workflow
gh run list

# Посмотрите логи последнего run
gh run view --log
```

## Шаг 7: Rollback (если нужно)

```bash
# Откатите Container App на предыдущую ревизию
az containerapp revision list \
  --name <relay-app-name> \
  --resource-group <resource-group>

az containerapp revision activate \
  --name <relay-app-name> \
  --resource-group <resource-group> \
  --revision <previous-revision>
```

## Полезные команды

### Проверка состояния ресурсов:

```bash
# Container App
az containerapp show \
  --name <relay-app-name> \
  --resource-group <resource-group> \
  --query '{fqdn: properties.configuration.ingress.fqdn, status: properties.runningStatus}'

# App Service
az webapp show \
  --name <web-app-name> \
  --resource-group <resource-group> \
  --query '{defaultHostName: defaultHostName, state: state}'

# ACR images
az acr repository list --name <acr-name>
az acr repository show-tags --name <acr-name> --repository yaok-relay
```

## Troubleshooting

### Pipeline fails на Azure Login:
- Проверьте federated credentials: subject должен соответствовать environment
- Убедитесь что RBAC роли назначены правильно

### Image push fails:
- Проверьте AcrPush/AcrPull роли для Managed Identity
- Убедитесь что ACR существует и доступен

### Deployment fails:
- Проверьте логи Container App: `az containerapp logs show`
- Проверьте логи App Service: `az webapp log tail`

## Безопасность

✅ **Что сделано:**
- OIDC authentication (без long-lived secrets)
- Separate Managed Identity для pipeline
- Role-based access control
- Environment-specific credentials
- Manual approvals для prod

❌ **Не храните в коде:**
- API keys
- Пароли
- Connection strings
- Токены

Используйте Azure Key Vault для application secrets.
