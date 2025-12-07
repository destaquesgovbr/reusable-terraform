# Plano de Implementação - Reusable Terraform

## Status Geral

| Fase | Descrição | Status |
|------|-----------|--------|
| 0 | Estrutura base | ✅ Concluído |
| 1 | Módulo api_enabling | ✅ Concluído |
| 2 | Módulo network | ✅ Concluído |
| 3 | Módulo iam | ✅ Concluído |
| 4 | Módulo sandbox | ✅ Concluído |
| 5 | Integração destaquesgovbr-infra | ✅ Concluído |
| 6 | Auto-shutdown de VMs | ✅ Concluído |
| 7 | Módulo clupa_data (BigQuery/GCS) | ⏳ Adiado |
| 8 | CI/CD com GitHub Actions | ⏳ Pendente |
| 9 | Versionamento no GitHub | ✅ Concluído |

---

## Fases Concluídas

### Fase 0-4: Módulos Base ✅
- `modules/api_enabling` - Habilitação de APIs GCP
- `modules/network` - VPC, subnet, NAT, firewall IAP
- `modules/iam` - Service accounts, roles, permissões
- `modules/sandbox` - VMs de desenvolvimento

### Fase 5: Integração ✅
- Arquivo `destaquesgovbr-infra/terraform/sandbox.tf` criado
- Variável `sandboxes` adicionada
- VM `nitai-sandbox` criada e funcionando
- Acesso via IAP SSH funcionando
- PR: https://github.com/destaquesgovbr/destaquesgovbr-infra/pull/8

### Fase 6: Auto-shutdown ✅
- Instance Schedule configurado via `google_compute_resource_policy`
- Desligamento automático às 19:00 (padrão) ou configurável
- Auto-start opcional (padrão: desligado)
- Timezone: America/Sao_Paulo

**Configuração:**
```hcl
auto_shutdown_enabled  = true           # Padrão: true
auto_shutdown_schedule = "0 19 * * *"   # Padrão: 19:00
auto_start_enabled     = false          # Padrão: false (manual)
auto_start_schedule    = "0 8 * * 1-5"  # Se habilitado: 08:00 dias úteis
schedule_timezone      = "America/Sao_Paulo"
```

### Fase 9: Versionamento ✅
- Repositório: https://github.com/destaquesgovbr/reusable-terraform
- Tags publicadas:
  - `v1.0.0` - Módulos base (api_enabling, network, iam, sandbox)
  - `v1.1.0` - Auto-shutdown support

---

## Próximas Fases

### Fase 8: CI/CD com GitHub Actions ⏳

**Objetivo:** Automatizar validação e deploy

**Arquivos a criar:**
```
.github/
└── workflows/
    └── terraform-validate.yml   # Valida PRs
```

**Workflow de validação:**
```yaml
name: Terraform Validate
on:
  pull_request:
    paths: ['**/*.tf']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check -recursive
      - run: |
          for dir in modules/*/; do
            terraform -chdir="$dir" init -backend=false
            terraform -chdir="$dir" validate
          done
```

---

### Fase 7: Módulo clupa_data (BigQuery/GCS) - ADIADO

**Objetivo:** Criar datasets BigQuery e buckets GCS compartilhados

**Status:** Adiado - será implementado quando necessário

**Estrutura planejada:**
```
modules/clupa_data/
├── main.tf
├── bigquery.tf      # Datasets: master, internal, output_clear, etc.
├── storage.tf       # Buckets: {data_product}-clupa, staging, temp
├── variables.tf
├── outputs.tf
└── README.md
```

---

## Decisões Técnicas

| Decisão | Escolha | Motivo |
|---------|---------|--------|
| Região | southamerica-east1 | Menor latência para Brasil |
| Imagem VM | ubuntu-2204-lts | Pública, estável, familiar |
| Google Group | Opcional | Simplifica setup inicial |
| OS Login | Desabilitado | Evita problemas com external users |
| Auto-start | Desabilitado por padrão | Desenvolvedor liga manualmente |
| clupa_data | Adiado | Não crítico para sandboxes |

---

## Comandos Úteis

```bash
# Validar módulos
cd reusable-terraform && make validate

# Aplicar mudanças
cd destaquesgovbr-infra/terraform && terraform apply

# Conectar à sandbox
gcloud compute ssh nitai-sandbox --zone=southamerica-east1-a --tunnel-through-iap

# Listar sandboxes
terraform output sandbox_ssh_commands

# Ligar VM manualmente
gcloud compute instances start nitai-sandbox --zone=southamerica-east1-a
```

---

## Histórico

| Data | Mudança |
|------|---------|
| 2024-12-06 | Criação inicial - Fases 0-5 concluídas |
| 2024-12-06 | VM nitai-sandbox criada e funcionando |
| 2024-12-06 | OS Login desabilitado (problema de permissões) |
| 2024-12-06 | Repositório GitHub criado (v1.0.0) |
| 2024-12-06 | Auto-shutdown implementado (v1.1.0) |
| 2024-12-06 | PR #8 criado no destaquesgovbr-infra |
