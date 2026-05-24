package terraform

import infra "github.com/rice-rob-inn-com-ent/rice/infra/proto/cue:infra"

// MASON defaults (| *) — CHIEF terraform.rice / Mint projectParams override root terraform.tfvars.

#TerraformParams: infra.#TerraformParams & {
	rice_environment:         string | *"dev"
	rice_cloud_provider:      string | *"aws"
	rice_github_org:          string | *"rice-rob-inn-com-ent"
	rice_github_repo:         string | *"rice"
	rice_domain:              string | *"dev.example.invalid"
	rice_k8s_cluster_name:    string | *"rice-dev"
	rice_db_instance_class:   string | *"db.t4g.micro"
	rice_registry:            string | *"ghcr.io"
	rice_region:              string | *"eu-west-1"
	rice_availability_zones:  [...string] | *["eu-west-1a", "eu-west-1b"]
	rice_vpc_cidr:            string | *"10.0.0.0/16"
	rice_enable_gpu:          bool | *false
	rice_gpu_instance_type:   string | *""
	rice_aws_region:          string | *"eu-west-1"
	rice_aws_assume_role_arn: string | *""
	rice_gcp_project_id:      string | *"replace-with-gcp-project-id"
	rice_gcp_region:          string | *"europe-west1"
	rice_azure_subscription_id: string | *""
	rice_azure_tenant_id:     string | *""
	rice_tf_backend:          string | *"local"
	rice_kubeconfig_path:     string | *"~/.kube/config"
	rice_enabled_clouds:      [...string] | *["aws"]
	rice_primary_cloud:       string | *"aws"
	rice_regions_aws:         [...string] | *["eu-west-1"]
	rice_regions_gcp:         [...string] | *["europe-west1"]
	rice_regions_azure:       [...string] | *[]
	rice_deployments: [...infra.#TerraformDeployment] | *[
		{cloud: "aws", region: "eu-west-1", vpc_cidr: "10.0.0.0/16"},
	]
}
