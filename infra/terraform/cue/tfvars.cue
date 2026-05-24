package terraform

import "strings"

// CHIEF-driven root terraform.tfvars (params merge in pack.cue).

_riceAzHcl: string
_riceAzHcl: strings.Join([ for z in params.rice_availability_zones { "\"\(z)\"" }], ", ")

_enableGpuHcl: *"false" | "true"
if params.rice_enable_gpu {
	_enableGpuHcl: "true"
}

_enabledCloudsHcl: strings.Join([ for c in params.rice_enabled_clouds { "\"\(c)\"" }], ", ")
_regionsAwsHcl: strings.Join([ for r in params.rice_regions_aws { "\"\(r)\"" }], ", ")
_regionsGcpHcl: strings.Join([ for r in params.rice_regions_gcp { "\"\(r)\"" }], ", ")
_regionsAzureHcl: strings.Join([ for r in params.rice_regions_azure { "\"\(r)\"" }], ", ")

_deploymentsEntries: [
	for d in params.rice_deployments {
		"\"\(d.cloud):\(d.region)\" = { cloud = \"\(d.cloud)\", region = \"\(d.region)\", vpc_cidr = \"\(d.vpc_cidr)\" }"
	},
]
_deploymentsHcl: strings.Join(_deploymentsEntries, ",\n  ")

rootTfvarsFile: [string]: string
rootTfvarsFile: {
	".opentofu/terraform.tfvars": """
		# Generated — cue cmd genTerraform. CHIEF: custom/*/infra/terraform.rice
		rice_environment         = "\(params.rice_environment)"
		rice_cloud_provider      = "\(params.rice_cloud_provider)"
		rice_github_org          = "\(params.rice_github_org)"
		rice_github_repo         = "\(params.rice_github_repo)"
		rice_domain              = "\(params.rice_domain)"
		rice_k8s_cluster_name    = "\(params.rice_k8s_cluster_name)"
		rice_db_instance_class   = "\(params.rice_db_instance_class)"
		rice_registry            = "\(params.rice_registry)"
		rice_region              = "\(params.rice_region)"
		rice_availability_zones  = [ \(_riceAzHcl) ]
		rice_vpc_cidr            = "\(params.rice_vpc_cidr)"
		rice_enable_gpu          = \(_enableGpuHcl)
		rice_gpu_instance_type   = "\(params.rice_gpu_instance_type)"
		rice_aws_region          = "\(params.rice_aws_region)"
		rice_aws_assume_role_arn = "\(params.rice_aws_assume_role_arn)"
		rice_gcp_project_id      = "\(params.rice_gcp_project_id)"
		rice_gcp_region          = "\(params.rice_gcp_region)"
		rice_azure_subscription_id = "\(params.rice_azure_subscription_id)"
		rice_azure_tenant_id     = "\(params.rice_azure_tenant_id)"
		rice_tf_backend          = "\(params.rice_tf_backend)"
		rice_kubeconfig_path     = "\(params.rice_kubeconfig_path)"
		rice_enabled_clouds      = [ \(_enabledCloudsHcl) ]
		rice_primary_cloud       = "\(params.rice_primary_cloud)"
		rice_regions = {
		  aws   = [ \(_regionsAwsHcl) ]
		  gcp   = [ \(_regionsGcpHcl) ]
		  azure = [ \(_regionsAzureHcl) ]
		}
		rice_regions_aws         = [ \(_regionsAwsHcl) ]
		rice_regions_gcp         = [ \(_regionsGcpHcl) ]
		rice_regions_azure       = [ \(_regionsAzureHcl) ]
		rice_deployments = {
		  \(_deploymentsHcl)
		}
		"""
}
