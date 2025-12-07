# Reusable Terraform - GCP Development Environments

Módulo Terraform reutilizável para provisionar ambientes de desenvolvimento (sandboxes) no Google Cloud Platform.

## Funcionalidades

- **VMs Sandbox**: VMs de desenvolvimento acessíveis via IAP (sem IP público)
- **Networking**: VPC isolada com NAT e firewall configurado para IAP
- **IAM**: Service accounts e permissões gerenciadas automaticamente
- **Flexível**: Google Group opcional, configuração por usuário individual

## Uso Rápido

```hcl
module "dev_environment" {
  source = "path/to/reusable-terraform"

  project_id   = "meu-projeto-gcp"
  data_product = "meu-produto"
  region       = "southamerica-east1"
  zone         = "southamerica-east1-a"

  sandbox = {
    sandboxes = {
      dev1 = {
        instance = {
          machine_type = "e2-standard-4"
          owner_email  = "desenvolvedor@empresa.com"
          image        = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
      }
    }
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Default |
|------|-----------|------|---------|
| `project_id` | GCP Project ID | `string` | (required) |
| `data_product` | Nome do produto (usado para nomear recursos) | `string` | (required) |
| `region` | Região GCP | `string` | `southamerica-east1` |
| `zone` | Zona GCP | `string` | `southamerica-east1-a` |
| `group_team_email` | Email do Google Group (opcional) | `string` | `null` |
| `enable_apis` | Habilitar módulo api_enabling | `bool` | `true` |
| `enable_network` | Habilitar módulo network | `bool` | `true` |
| `enable_iam` | Habilitar módulo iam | `bool` | `true` |
| `sandbox` | Configuração das VMs sandbox | `object` | `{}` |

## Outputs

| Nome | Descrição |
|------|-----------|
| `network_id` | ID da VPC |
| `sandbox_service_account_email` | Email da SA das sandboxes |
| `sandbox_ssh_commands` | Comandos SSH para conectar às VMs via IAP |

## Conectando às VMs

Após o deploy, conecte-se via IAP:

```bash
gcloud compute ssh {sandbox-name}-sandbox \
  --zone=southamerica-east1-a \
  --tunnel-through-iap
```

## Módulos

- `modules/api_enabling` - Habilitação de APIs GCP
- `modules/network` - VPC, subnet, NAT, firewalls
- `modules/iam` - Service accounts e permissões
- `modules/sandbox` - VMs de desenvolvimento

## Desenvolvimento

```bash
# Validar todos os módulos
make validate

# Formatar código
make fmt

# Testar com exemplo
make example-init
make example-plan
```

## Requisitos

- Terraform >= 1.5.0
- Google Cloud Provider ~> 5.0
- gcloud CLI configurado
