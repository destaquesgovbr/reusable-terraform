# Plano de Implementação - Reusable Terraform

## Status Geral

| Fase | Descrição | Status |
|------|-----------|--------|
| 0 | Estrutura base + CI/CD | ✅ Concluído |
| 1 | Módulo api_enabling | ✅ Concluído |
| 2 | Módulo network | ✅ Concluído |
| 3 | Módulo iam | ✅ Concluído |
| 4 | Módulo sandbox | ✅ Concluído |
| 5 | Integração destaquesgovbr-infra | ✅ Concluído |
| 6 | Auto-shutdown de VMs | ⏳ Pendente |
| 7 | Módulo clupa_data (BigQuery/GCS) | ⏳ Pendente |
| 8 | CI/CD com GitHub Actions | ⏳ Pendente |
| 9 | Versionamento no GitHub | ⏳ Pendente |

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

---

## Próximas Fases

### Fase 6: Auto-shutdown de VMs ⏳

**Objetivo:** Desligar VMs automaticamente para economizar custos

**Opções de implementação:**

#### Opção A: Instance Schedules (Recomendado)
```hcl
resource "google_compute_resource_policy" "auto_shutdown" {
  name   = "sandbox-auto-shutdown"
  region = var.region

  instance_schedule_policy {
    vm_stop_schedule {
      schedule = "0 19 * * *"  # 19:00 UTC diariamente
    }
    time_zone = "America/Sao_Paulo"
  }
}
```

**Vantagens:**
- Gerenciado pelo GCP
- Configurável via Terraform
- Pode incluir auto-start de manhã

#### Opção B: Cron na VM
- Configurar cron job na imagem base
- `0 19 * * * sudo shutdown -h now`

**Arquivos a modificar:**
- `modules/sandbox/variables.tf` - Adicionar variável `auto_shutdown`
- `modules/sandbox/schedule.tf` - Novo arquivo para resource policy

---

### Fase 7: Módulo clupa_data (BigQuery/GCS) ⏳

**Objetivo:** Criar datasets BigQuery e buckets GCS compartilhados

**Estrutura:**
```
modules/clupa_data/
├── main.tf
├── bigquery.tf      # Datasets: master, internal, output_clear, etc.
├── storage.tf       # Buckets: {data_product}-clupa, staging, temp
├── variables.tf
├── outputs.tf
└── README.md
```

**Datasets a criar:**
- `master` - Dados materializados
- `internal` - Dados internos
- `output_clear` - Views de dados claros
- `output_preversible` - Views pseudo-reversíveis
- `ignore` - Temporário Spark-BigQuery

**Buckets a criar:**
- `{data_product}-clupa` - Código fonte
- `dataproc-staging-{data_product}` - Staging
- `dataproc-temp-{data_product}` - Temporários

---

### Fase 8: CI/CD com GitHub Actions ⏳

**Objetivo:** Automatizar validação e deploy

**Arquivos a criar:**
```
.github/
└── workflows/
    ├── terraform-validate.yml   # Valida PRs
    ├── terraform-plan.yml       # Plan em PRs
    └── terraform-apply.yml      # Apply no merge
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

### Fase 9: Versionamento no GitHub ⏳

**Objetivo:** Publicar módulo no GitHub com versionamento semântico

**Passos:**
1. Criar repositório `destaquesgovbr/reusable-terraform`
2. Push do código atual
3. Criar tag `v1.0.0`
4. Atualizar referência em `destaquesgovbr-infra`:
   ```hcl
   module "dev_sandbox" {
     source = "git@github.com:destaquesgovbr/reusable-terraform.git?ref=v1.0.0"
     # ...
   }
   ```

---

## Decisões Técnicas

| Decisão | Escolha | Motivo |
|---------|---------|--------|
| Região | southamerica-east1 | Menor latência para Brasil |
| Imagem VM | ubuntu-2204-lts | Pública, estável, familiar |
| Google Group | Opcional | Simplifica setup inicial |
| OS Login | Desabilitado | Evita problemas com external users |
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
```

---

## Histórico

| Data | Mudança |
|------|---------|
| 2024-12-06 | Criação inicial - Fases 0-5 concluídas |
| 2024-12-06 | VM nitai-sandbox criada e funcionando |
| 2024-12-06 | OS Login desabilitado (problema de permissões) |
