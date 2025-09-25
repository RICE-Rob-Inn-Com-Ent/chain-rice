# =============================================================================
# CI/CD MODULE - OUTPUTS
# =============================================================================

output "pipeline_url" {
  description = "URL of the CI/CD pipeline"
  value       = local.pipeline_url
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = local.codebuild_project_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = local.codepipeline_name
}
