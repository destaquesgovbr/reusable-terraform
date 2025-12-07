# Requisitos Funcionais - Infraestrutura Terraform para Ambientes de Desenvolvimento GCP

Este documento descreve os requisitos funcionais extraídos do repositório `aa-reusable-terraform` para replicação da arquitetura de provimento de ambientes de desenvolvimento na nuvem GCP.

## Escopo

**Incluído neste levantamento:**
- VMs sandbox para desenvolvimento
- Datasets BigQuery
- Buckets GCS
- Configuração de rede
- IAM e Service Accounts
- Workflows CI/CD

**Fora do escopo (não necessário no novo ambiente):**
- Dataproc (serverless e cluster)
- MLFlow
- Integrações específicas (Astronomer, Starburst)

---

## 1. Arquitetura Geral

### 1.1 Estrutura de Módulos

```
reusable-terraform/
├── main.tf                    # Orquestração dos módulos
├── variables.tf               # Variáveis de entrada
├── locals.tf                  # Configurações locais (SAs, nomes, roles)
├── outputs.tf                 # Saídas do módulo
└── modules/
    ├── api_enabling/          # Habilitação de APIs GCP
    ├── network/               # VPC, subnets, firewalls, NAT
    ├── iam/                   # Service accounts, roles, permissões
    ├── clupa_data/            # Buckets e datasets principais
    └── sandbox/               # VMs de desenvolvimento
```

### 1.2 Ordem de Criação dos Recursos

1. **api_enabling** - Habilitar APIs necessárias
2. **network** - Criar VPC, subnets, firewalls, NAT
3. **iam** - Criar service accounts e configurar permissões
4. **clupa_data** - Criar buckets e datasets compartilhados
5. **sandbox** - Criar VMs e recursos por desenvolvedor

---

## 2. VMs Sandbox

### 2.1 Requisitos Funcionais

| ID | Requisito | Descrição |
|----|-----------|-----------|
| VM-01 | Criação de VMs individuais | Cada desenvolvedor pode ter sua própria VM |
| VM-02 | VMs compartilhadas | Opção de criar VMs acessíveis por todo o grupo |
| VM-03 | Autenticação automática | VMs devem autenticar automaticamente com SA pré-configurada |
| VM-04 | Acesso via IAP | Acesso SSH via Identity-Aware Proxy (sem IP público) |
| VM-05 | Disco persistente | Dados do usuário em disco separado que persiste recriações |
| VM-06 | Configuração flexível | Machine type, disco, imagem configuráveis por VM |
| VM-07 | Subnetwork customizada | Opção de especificar subnetwork diferente por VM |

### 2.2 Especificação Técnica das VMs

```hcl
# Estrutura de configuração por sandbox
sandboxes = {
  nome_sandbox = {
    instance = {
      machine_type      = string           # Ex: "e2-standard-4"
      owner_email       = optional(string) # Email do proprietário (null = compartilhada)
      version           = string           # "v2" (recomendado)
      image             = string           # Imagem GCE
      boot_disk_type    = optional(string, "pd-standard")
      boot_disk_size_gb = optional(number, 100)
      data_disk_type    = optional(string, "pd-standard")
      data_disk_size_gb = optional(number, 100)
      subnetwork        = optional(string) # Subnetwork customizada
    }
    bucket = optional({
      bucket_public_access_prevention = optional(string, "enforced")
    })
  }
}
```

### 2.3 Recursos Criados por Sandbox

Para cada sandbox definida, são criados automaticamente:

1. **Compute Instance** (`google_compute_instance`)
   - Nome: `{sandbox_name}-sandbox`
   - Service Account: `sa-w-sandbox@{project_id}.iam.gserviceaccount.com`
   - Sem IP público
   - OSLogin habilitado

2. **Disco de Dados Persistente** (`google_compute_disk`)
   - Nome: `{sandbox_name}-sandbox-data`
   - Lifecycle: `prevent_destroy = true` (proteção contra destruição acidental)

3. **Dataset BigQuery** (`google_bigquery_dataset`)
   - ID: `{sandbox_name}_sandbox`
   - Permissões: SA sandbox (WRITER), grupo (WRITER)

4. **Bucket GCS** (`google_storage_bucket`)
   - Nome: `{sandbox_name}-sandbox-{data_product}`
   - Permissões: SA sandbox (admin)

### 2.4 Autenticação Automática nas VMs

**Mecanismo:** A VM é criada com uma Service Account anexada. Qualquer código executado dentro da VM herda automaticamente as permissões dessa SA.

```hcl
resource "google_compute_instance" "sandbox" {
  # ...
  service_account {
    email  = var.sandbox_service_account.email  # sa-w-sandbox@...
    scopes = ["cloud-platform"]                 # Acesso completo às APIs
  }
}
```

**Consequências:**
- Não é necessário `gcloud auth login` na VM
- Bibliotecas Python (google-cloud-*) funcionam automaticamente
- `gcloud` CLI funciona sem configuração adicional

### 2.5 Controle de Acesso às VMs

**VM com owner_email definido:**
```hcl
resource "google_iap_tunnel_instance_iam_member" "sandbox_iap_access" {
  instance = "${sandbox_name}-sandbox"
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${owner_email}"
}
```
- Apenas o proprietário pode acessar via IAP

**VM sem owner_email (compartilhada):**
```hcl
resource "google_iap_tunnel_instance_iam_member" "shared_sandbox_iap_access" {
  instance = "${sandbox_name}-sandbox"
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "group:${group_team_email}"
}
```
- Todo o grupo pode acessar via IAP

### 2.6 Imagem Base da VM

**Não há Dockerfile no repositório.** As imagens são GCE Images pré-existentes:

| Tipo | Imagem Padrão | Origem |
|------|---------------|--------|
| v1 (Notebooks) | `deeplearning-platform-release/common-cpu-notebooks-v20231105-debian-11` | Google Public |
| v2 (Compute) | `projects/{project}/global/images/clupa-dev-v13-20240725` | Custom Image |

**Requisito para novo ambiente:**
- Criar imagem customizada com ferramentas necessárias (Python, bibliotecas, etc.)
- Usar Packer ou processo manual para criar a imagem
- Hospedar a imagem no projeto GCP de infraestrutura

---

## 3. BigQuery Datasets

### 3.1 Datasets Principais (clupa_data)

| Dataset | Propósito | Escrita | Leitura |
|---------|-----------|---------|---------|
| `master` | Dados materializados para compartilhamento | SA compute | Grupo, SA sandbox |
| `internal` | Dados internos do projeto | SA compute | Grupo, SA sandbox |
| `output_clear` | Views de dados claros | SA compute | Grupo, SA sandbox |
| `output_preversible` | Views de dados pseudo-reversíveis | SA compute | Grupo, SA sandbox |
| `ignore` | Temporário Spark-BigQuery | Grupo, SA compute, SA sandbox | - |

### 3.2 Datasets por Sandbox

| Dataset | ID | Permissões |
|---------|-----|-----------|
| Sandbox Dataset | `{sandbox_name}_sandbox` | SA sandbox (WRITER), Grupo (WRITER) |

### 3.3 Especificação Técnica

```hcl
resource "google_bigquery_dataset" "example" {
  project     = var.project_id
  dataset_id  = "dataset_name"
  description = "Descrição do dataset"
  location    = "europe-west1"
}

resource "google_bigquery_dataset_access" "writer_access" {
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.example.dataset_id
  role          = "WRITER"
  user_by_email = "sa-w-sandbox@{project_id}.iam.gserviceaccount.com"
}
```

---

## 4. Buckets GCS

### 4.1 Buckets Principais

| Bucket | Nome | Propósito | Permissões |
|--------|------|-----------|------------|
| Projeto | `{data_product}-clupa` | Código fonte e arquivos | SA compute (admin) |
| Staging | `dataproc-staging-{data_product}` | Staging de jobs | Grupo (admin), SA compute (admin) |
| Temp | `dataproc-temp-{data_product}` | Arquivos temporários | Grupo (admin), SA compute (admin) |

### 4.2 Buckets por Sandbox

| Bucket | Nome | Permissões |
|--------|------|------------|
| Sandbox | `{sandbox_name}-sandbox-{data_product}` | SA sandbox (admin) |

### 4.3 Especificação Técnica

```hcl
resource "google_storage_bucket" "example" {
  project       = var.project_id
  name          = "bucket-name"
  location      = "europe-west1"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

resource "google_storage_bucket_iam_member" "admin_access" {
  bucket = google_storage_bucket.example.name
  role   = "roles/storage.admin"
  member = "serviceAccount:sa-w-sandbox@{project_id}.iam.gserviceaccount.com"
}
```

---

## 5. Network

### 5.1 Componentes de Rede

| Componente | Nome | Configuração |
|------------|------|--------------|
| VPC | `default` | auto_create_subnetworks = false |
| Subnet | `default` | CIDR: 10.128.0.0/9, Private Google Access |
| Router | `my-router` | BGP ASN: 64514 |
| NAT | `my-router-nat` | AUTO_ONLY, todos os ranges |
| Firewall IAP | `iap-firewall-rule` | Source: 35.235.240.0/20, Ports: 22, 3389 |
| Firewall Internal | `dataproc-firewall-rule` | Source: 10.128.0.0/9, All TCP/UDP |

### 5.2 Especificação Técnica

```hcl
# VPC
resource "google_compute_network" "main" {
  name                    = "default"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name                     = "default"
  ip_cidr_range            = "10.128.0.0/9"
  region                   = "europe-west1"
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

# Router + NAT
resource "google_compute_router" "main" {
  name    = "my-router"
  region  = "europe-west1"
  network = google_compute_network.main.id
  bgp { asn = 64514 }
}

resource "google_compute_router_nat" "main" {
  name                               = "my-router-nat"
  router                             = google_compute_router.main.name
  region                             = "europe-west1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall IAP
resource "google_compute_firewall" "iap" {
  name          = "iap-firewall-rule"
  network       = google_compute_network.main.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]  # Range do IAP
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}
```

---

## 6. IAM e Service Accounts

### 6.1 Service Accounts

| SA ID | Propósito | Roles |
|-------|-----------|-------|
| `sa-w-sandbox` | VMs sandbox | bigquery.user, logging.logWriter, secretmanager.viewer, secretmanager.secretAccessor |
| `sa-w-terraform-ci` | CI/CD Terraform | Roles administrativos (ver script setup-iam.sh) |

### 6.2 Roles do sa-w-sandbox

```hcl
roles = [
  "roles/bigquery.user",
  "roles/logging.logWriter",
  "roles/secretmanager.viewer",
  "roles/secretmanager.secretAccessor",
]
```

### 6.3 Roles do Grupo de Desenvolvedores

```hcl
roles = [
  "roles/bigquery.user",
  "roles/storage.objectViewer",
  "roles/compute.viewer",
  "roles/compute.networkViewer",
  "roles/secretmanager.viewer",
  "roles/logging.viewer",
  "roles/compute.osAdminLogin",  # SSH com sudo via OSLogin
]
```

### 6.4 Custom Role para Operações Manuais

```hcl
resource "google_project_iam_custom_role" "resource_editor" {
  role_id     = "resourceEditor"
  title       = "Resource Editor"
  permissions = [
    "compute.instances.stop",
    "compute.instances.start",
    "compute.instances.suspend",
    "compute.instances.resume",
    "compute.instances.reset",
    "storage.buckets.list",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
}
```

### 6.5 IAM Bindings Importantes

```hcl
# Grupo pode usar a SA sandbox para submeter jobs
resource "google_service_account_iam_member" "group_use_sandbox_sa" {
  service_account_id = "projects/{project}/serviceAccounts/sa-w-sandbox@{project}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "group:{group_email}"
}

# SA sandbox pode impersonar ela mesma (para chains de impersonation)
resource "google_service_account_iam_member" "sandbox_impersonate_self" {
  service_account_id = "projects/{project}/serviceAccounts/sa-w-sandbox@{project}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:sa-w-sandbox@{project}.iam.gserviceaccount.com"
}
```

---

## 7. APIs GCP Necessárias

```hcl
gcp_services = [
  "iam.googleapis.com",
  "compute.googleapis.com",
  "bigquery.googleapis.com",
  "storage.googleapis.com",
  "secretmanager.googleapis.com",
  "servicenetworking.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "iap.googleapis.com",
]
```

---

## 8. CI/CD - Workflows GitHub Actions

### 8.1 Setup Inicial (Scripts Bash)

#### Script 1: setup-iam.sh

**Requisitos:**
- `PROJECT_ID`: ID do projeto GCP
- `USER_EMAIL`: Email do usuário executando
- `GROUP_EMAIL`: Google Group do projeto

**Ações:**
1. Grant `serviceusage.serviceUsageAdmin` ao usuário
2. Habilitar APIs: `iamcredentials`, `serviceusage`, `cloudidentity`, `cloudresourcemanager`
3. Grant `iam.serviceAccountAdmin`, `iam.roleAdmin` ao usuário
4. Criar custom role `Terraform`
5. Criar SA `sa-w-terraform-ci`
6. Grant roles administrativos à SA:
   - `artifactregistry.admin`, `iap.admin`, `compute.admin`
   - `storage.admin`, `bigquery.admin`, `iam.*`
7. Adicionar SA ao Google Group

#### Script 2: setup-wif.sh

**Requisitos:**
- `PROJECT_ID`: ID do projeto GCP
- `GITHUB_REPO_ID`: ID numérico do repositório GitHub

**Ações:**
- Configurar Workload Identity Federation para permitir GitHub Actions autenticar como SA

```bash
# Principal set para cada workflow
PRINCIPAL_SET="principalSet://iam.googleapis.com/projects/{org_project}/locations/global/workloadIdentityPools/org-cicd/attribute.github/{repo_id}:{workflow_name}"

# Grant workloadIdentityUser
gcloud iam service-accounts add-iam-policy-binding "sa-w-terraform-ci@{project}.iam.gserviceaccount.com" \
  --member="$PRINCIPAL_SET" \
  --role="roles/iam.workloadIdentityUser"
```

### 8.2 Workflow Terraform

**Arquivo:** `.github/workflows/terraform-{env}.yml`

```yaml
name: terraform-dev

on:
  push:
    branches: [main]
    paths: ['infrastructure/environments/dev/**']
  pull_request:
    branches: [main]
    paths: ['infrastructure/environments/dev/**']

permissions: read-all

jobs:
  terraform:
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    uses: {org}/de-reusable-workflows/.github/workflows/terraform-clupa.yml@v1.x.x
    with:
      WORKING_DIRECTORY: 'infrastructure/environments/dev'
      ENVIRONMENT: dev
      GCP_PROJECT: {project_id}
    secrets:
      GCP_WIF_PROVIDER_ID: ${{ secrets.GCP_WIF_PROVIDER_ID }}
      SSH_KEY_REUSABLE_TERRAFORM: ${{ secrets.SSH_KEY_REUSABLE_TERRAFORM }}
```

### 8.3 Fluxo CI/CD

1. **Pull Request:** Executa `terraform plan` e posta resultado como comentário
2. **Merge:** Executa `terraform apply` automaticamente

---

## 9. Auto-Shutdown de VMs

### 9.1 Implementação Atual

**Implementado via cron job na imagem da VM.** A imagem base inclui um cron configurado no root crontab para desligar a VM automaticamente.

```bash
# Cron job configurado na imagem (root crontab)
0 19 * * * sudo shutdown -h now
```

Isso significa que a VM é desligada às **19:00 GMT** todos os dias.

### 9.2 Personalização pelo Usuário

Os usuários podem personalizar o auto-shutdown acessando a VM:

```bash
# Editar crontab do root
sudo crontab -e

# Alterar horário (ex: 21:30 GMT)
30 21 * * * sudo shutdown -h now

# Ou desabilitar completamente (comentar a linha)
# 0 19 * * * sudo shutdown -h now
```

### 9.3 Opções Alternativas para Novo Ambiente

#### Opção A: Cron na Imagem (Atual)

**Vantagens:**
- Simples de implementar na imagem
- Usuário pode customizar individualmente
- Não requer recursos GCP adicionais

**Desvantagens:**
- Requer que a imagem seja atualizada para mudar o padrão
- Usuário precisa acessar a VM para alterar

#### Opção B: Instance Schedules (GCP Native)

```hcl
resource "google_compute_resource_policy" "instance_schedule" {
  name   = "sandbox-schedule"
  region = "europe-west1"

  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 8 * * 1-5"  # 08:00 Mon-Fri
    }
    vm_stop_schedule {
      schedule = "0 20 * * 1-5"  # 20:00 Mon-Fri
    }
    time_zone = "Europe/Lisbon"
  }
}

resource "google_compute_instance" "sandbox" {
  # ...
  resource_policies = [google_compute_resource_policy.instance_schedule.self_link]
}
```

**Vantagens:**
- Gerenciado centralmente via Terraform
- Pode incluir start automático de manhã
- Mais visibilidade e controle

**Desvantagens:**
- Menos flexível para usuários individuais
- Requer recurso GCP adicional

**Recomendação:** Para novo ambiente, considerar **Opção B (Instance Schedules)** como padrão por ser mais controlável, com opção de override via Terraform por sandbox específica.

---

## 10. Conexão às VMs via VSCode + IAP

### 10.1 Visão Geral

O acesso às VMs é feito via **Identity-Aware Proxy (IAP)** tunneling, sem necessidade de IP público. Usa-se o VSCode com a extensão Remote-SSH para desenvolvimento.

### 10.2 Pré-requisitos

1. **gcloud CLI** instalado e autenticado (`gcloud auth login`)
2. **Python** instalado (necessário para o proxy IAP)
3. **VSCode** com extensão **Remote-SSH**
4. Permissão `roles/iap.tunnelResourceAccessor` na VM

### 10.3 Fluxo de Conexão

```
[Desenvolvedor] → [gcloud IAP tunnel] → [VM Sandbox]
       ↓
   VSCode Remote-SSH
```

### 10.4 Configuração SSH (Mac/Linux)

1. Autenticar no gcloud:
```bash
gcloud auth login
```

2. Obter comando SSH com dry-run:
```bash
gcloud compute ssh {sandbox-name}-sandbox \
  --project {project_id} \
  --zone europe-west1-b \
  --tunnel-through-iap \
  --dry-run
```

3. Copiar output para `~/.ssh/config` no VSCode (Command Palette → Remote-SSH: Add new SSH host)

4. Conectar via VSCode (Remote-SSH: Connect to Host)

### 10.5 Configuração SSH (Windows)

Arquivo `C:/Users/{user}/.ssh/config`:

```
Host {connection_name}
  HostName compute.{instance_id}
  ForwardAgent yes
  IdentityFile C:/Users/{user}/.ssh/google_compute_engine
  ProxyCommand "C:/Users/{user}/AppData/Local/Programs/Python/Python312/python.exe" "-S" "C:/Users/{user}/AppData/Local/Google/Cloud SDK/google-cloud-sdk/lib/gcloud.py" compute start-iap-tunnel {sandbox-name}-sandbox %p --listen-on-stdin --project {project_id} --zone=europe-west1-b --verbosity=warning
  User {username}
```

Onde:
- `{connection_name}`: Nome para a conexão no VSCode
- `{instance_id}`: ID da instância (obtido via `--dry-run`)
- `{sandbox-name}`: Nome da sandbox VM
- `{project_id}`: ID do projeto GCP
- `{username}`: Username OSLogin (ex: `joao_silva_empresa_com`)

### 10.6 Primeiro Acesso (Gerar Chaves SSH)

Na primeira conexão, executar para gerar chaves e registrar no GCP:

```bash
gcloud compute ssh {sandbox-name}-sandbox \
  --project {project_id} \
  --zone europe-west1-b \
  --tunnel-through-iap \
  --quiet
```

### 10.7 Ambiente de Desenvolvimento na VM

Após conectar, criar ambiente Python isolado:

```bash
# Desativar conda base (se existir)
conda deactivate

# Criar venv
python3 -m venv ~/my_env
source ~/my_env/bin/activate

# Atualizar pip
python -m pip install --upgrade pip

# Instalar dependências do projeto
pip install -r requirements.txt
```

### 10.8 Documentação para Usuários

Criar documentação para os usuários finais incluindo:
- Pré-requisitos de instalação
- Passo a passo de configuração
- Troubleshooting comum
- Como ligar/desligar VM manualmente

---

## 11. Estrutura de Arquivos por Ambiente

### 11.1 Estrutura Mínima (Recomendada)

Como o módulo reusable abstrai toda a complexidade, o projeto consumidor pode ter apenas **1 arquivo**:

```
infrastructure/
└── environments/
    └── {env}/
        └── main.tf    # Tudo em um único arquivo
```

### 11.2 Arquivo Único: main.tf

```hcl
# ============================================
# BACKEND (state remoto)
# ============================================
terraform {
  backend "gcs" {
    bucket                      = "meu-projeto-dev-terraform-state"
    impersonate_service_account = "sa-w-terraform-ci@meu-projeto-dev-123456.iam.gserviceaccount.com"
  }
}

# ============================================
# MÓDULO REUSABLE
# ============================================
module "infra" {
  source = "git@github.com:{org}/reusable-terraform.git?ref=v1.0.0"

  # Configurações do projeto
  project_id       = "meu-projeto-dev-123456"
  project_number   = "123456789"
  data_product     = "meu-projeto"
  group_team_email = "meu-projeto-devs@empresa.com"

  # Flags dos módulos ativos
  enable_APIs    = true
  enable_iam     = true
  enable_network = true

  # Sandboxes
  sandbox = {
    sandboxes = {
      desenvolvedor1 = {
        instance = {
          machine_type = "e2-standard-4"
          owner_email  = "dev1@empresa.com"
          version      = "v2"
          image        = "projects/infra-project/global/images/base-dev-v1"
        }
      }
      compartilhada = {
        instance = {
          machine_type = "e2-standard-8"
          version      = "v2"
          image        = "projects/infra-project/global/images/base-dev-v1"
        }
      }
    }
  }

  # BigQuery e Buckets (opcional - pode usar defaults)
  clupa_data = {}  # Usa configuração padrão
}
```

### 11.3 Por que funciona com 1 arquivo?

| Aspecto | Solução |
|---------|---------|
| **Variables** | Valores inline no módulo (não precisa de `variables.tf`) |
| **Locals** | O módulo reusable já define todos os locals internamente |
| **Data sources** | O módulo reusable busca os dados necessários |
| **Outputs** | Acessíveis via `module.infra.{output_name}` se necessário |

### 11.4 Alternativa: 2 arquivos (para separar configuração)

Se preferir separar configuração de código para facilitar edições:

```
infrastructure/
└── environments/
    └── {env}/
        ├── main.tf          # Chamada do módulo (fixo)
        └── terraform.tfvars # Valores específicos (editável)
```

**main.tf:**
```hcl
terraform {
  backend "gcs" {
    bucket                      = var.state_bucket
    impersonate_service_account = var.terraform_sa
  }
}

variable "project_id" {}
variable "project_number" {}
variable "data_product" {}
variable "group_team_email" {}
variable "sandbox" { default = null }
variable "state_bucket" {}
variable "terraform_sa" {}

module "infra" {
  source           = "git@github.com:{org}/reusable-terraform.git?ref=v1.0.0"
  project_id       = var.project_id
  project_number   = var.project_number
  data_product     = var.data_product
  group_team_email = var.group_team_email
  sandbox          = var.sandbox
}
```

**terraform.tfvars:**
```hcl
state_bucket     = "meu-projeto-dev-terraform-state"
terraform_sa     = "sa-w-terraform-ci@meu-projeto-dev-123456.iam.gserviceaccount.com"
project_id       = "meu-projeto-dev-123456"
project_number   = "123456789"
data_product     = "meu-projeto"
group_team_email = "meu-projeto-devs@empresa.com"

sandbox = {
  sandboxes = {
    dev1 = {
      instance = {
        machine_type = "e2-standard-4"
        owner_email  = "dev1@empresa.com"
        version      = "v2"
        image        = "projects/infra-project/global/images/base-dev-v1"
      }
    }
  }
}
```

---

## 12. Considerações sobre CDK for Terraform (CDKTF)

### 12.1 O que é

CDKTF permite escrever infraestrutura em Python (ou outras linguagens) em vez de HCL.

### 12.2 Tradeoffs

| Aspecto | HCL Tradicional | CDKTF Python |
|---------|-----------------|--------------|
| Curva de aprendizado | Baixa (DSL simples) | Média (requer Python) |
| Flexibilidade | Limitada | Alta (lógica programática) |
| Debugging | Simples | Mais complexo |
| State management | Nativo | Via adapters |
| Comunidade | Grande | Crescendo |
| IDE support | Bom | Muito bom (Python) |
| Testes | terraform-compliance | pytest nativo |

### 12.3 Recomendação

Para um projeto novo com escopo limitado (VMs, BigQuery, Buckets), **HCL tradicional é suficiente**.

Considerar CDKTF se:
- Equipe já domina Python
- Necessidade de lógica complexa de configuração
- Desejo de reutilizar bibliotecas Python existentes
- Necessidade de testes unitários extensivos

---

## 13. Checklist de Implementação

### Fase 1: Setup Inicial
- [ ] Criar projeto GCP
- [ ] Criar Google Group para a equipe
- [ ] Criar bucket para Terraform state
- [ ] Executar setup-iam.sh
- [ ] Executar setup-wif.sh
- [ ] Criar repositório GitHub
- [ ] Configurar secrets do GitHub (WIF_PROVIDER_ID, SSH_KEY)

### Fase 2: Infraestrutura Base
- [ ] Criar módulo api_enabling
- [ ] Criar módulo network
- [ ] Criar módulo iam
- [ ] Testar deploy via PR

### Fase 3: Recursos de Dados
- [ ] Criar módulo para buckets principais
- [ ] Criar módulo para datasets principais
- [ ] Configurar permissões

### Fase 4: Sandboxes
- [ ] Criar/selecionar imagem base para VMs
- [ ] Criar módulo sandbox
- [ ] Testar criação de VM individual
- [ ] Testar criação de VM compartilhada
- [ ] Validar autenticação automática

### Fase 5: Otimizações
- [ ] Implementar auto-shutdown (opcional)
- [ ] Documentar processo para usuários
- [ ] Criar runbook de operações

---

## 14. Referências

- Código fonte: `/home/nitai_silva_parceiros_nos_pt/projects/aa-reusable-terraform`
- Exemplo de uso: `/home/nitai_silva_parceiros_nos_pt/projects/aa-reusable-terraform/examples/my-clupa-environment`
- Projeto real: `/home/nitai_silva_parceiros_nos_pt/projects/aa-cloud-demo-busdp-main/infrastructure/environments/lab`
- Documentação de conexão via VSCode: `/home/nitai_silva_parceiros_nos_pt/projects/clupa-core/docs/infra/development-sandbox.md`
