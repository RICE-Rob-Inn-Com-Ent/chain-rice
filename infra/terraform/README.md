# MASON OpenTofu (`infra/terraform`)

Generates **`.opentofu/`** at repo root (modules, environments, providers, root `*.tf`, CHIEF-driven `terraform.tfvars`).

## Layout

| Path | Role |
|------|------|
| [`_tool.cue`](_tool.cue) | `cue cmd genTerraform` |
| [`cue/pack.cue`](cue/pack.cue) | `params`, paths, `allFiles` roll-up |
| [`cue/main.cue`](cue/main.cue) | Root `main.tf`, `variables.tf`, `providers.tf`, `versions.tf`, `outputs.tf` |
| [`cue/modules.cue`](cue/modules.cue) | `modules/**` skeleton |
| [`cue/environments.cue`](cue/environments.cue) | `environments/{dev,stag,prod}/**` |
| [`cue/providers.cue`](cue/providers.cue) | `providers/{aws,gcp,azure}/**` |
| [`cue/tfvars.cue`](cue/tfvars.cue) | Root `terraform.tfvars` from `params` |
| [`cue/defaults.cue`](cue/defaults.cue) | MASON `#TerraformParams` defaults |
| [`../proto/cue/infra.cue`](../proto/cue/infra.cue) | Mint/Rice schema |

## CHIEF

```ini
# bowl
[package]
infra = ""
```

```rice
use infra as terraform

rc terraform let {
  environment set { name = dev, cloud_provider = aws, domain = egos.app, region = eu-west-1 }
  github set { org = rice-rob-inn-com-ent, repo = rice }
  cluster set { k8s_name = egos-dev, db_class = db.t4g.micro, registry = ghcr.io }

  clouds set {
    enabled = (aws, gcp)
    primary = aws
  }

  regions set {
    aws = (eu-west-1, us-east-1)
    gcp = (europe-west1)
  }

  network set {
    vpc_cidr = 10.0.0.0/16
    aws.eu-west-1.vpc_cidr = 10.0.0.0/16
    aws.us-east-1.vpc_cidr = 10.1.0.0/16
    availability_zones = (eu-west-1a, eu-west-1b)
  }

  aws set { region = eu-west-1, assume_role_arn = }
  gcp set { project_id = replace-with-gcp-project-id, region = europe-west1 }
  azure set { subscription_id =, tenant_id = }
  gpu set { enabled = false, instance_type = }
  state set { backend = local, kubeconfig_path = "~/.kube/config" }
}
```

Mint builds `rice_deployments` (keys `cloud:region`) → OpenTofu `for_each` on `clusters`, `databases`, `stores`, `kubernetes`. Singleton modules: `auth`, `certificates`, `routes`.

## IDE (Rice infra)

- Syntax: install [`../vscode/extensions/rice-infra`](../vscode/extensions/rice-infra) via **Extensions: Install from Location…**
- Lint: `cargo run -p mint --bin mint_overlay_check` or workspace task **Rice: validate CHIEF infra**
- LSP: `cargo build -p mint --bin rice-lsp` — diagnostics + format on `custom/*/infra/*.rice` and `bowl`

## Generate

```bash
export CHIEF_PROJECT=egos.app
cargo run -p mint --bin mint_overlay_check -- --apply-terraform
cue cmd gen ./infra/_tool.cue
```

Or only terraform: `cue cmd genTerraform ./infra/terraform/_tool.cue ./infra/terraform/cue/**/*.cue ./infra/gen/chief/terraform_project.cue`
