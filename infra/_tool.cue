package rice

import "tool/exec"

folder_sync: [
	{source: "infra/kubernetes", target: ".kubernetes"},
	{source: "infra/reuse",      target: ".reuse"},
	{source: "infra/vscode",     target: ".vscode"},
]

// genMonorepo — rice pour: MASON skeleton from committed infra/gen/chief/* (no Mint, no CHIEF_PROJECT).
command: genMonorepo: {
	vet_docker: exec.Run & {
		display: "🔍 Vetting infra/docker (monorepo)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/docker/_tool.cue ./infra/docker/cue/**/*.cue ./infra/gen/chief/docker_project.cue ./infra/gen/chief/server_project.cue ./infra/gen/chief/docs_project.cue ./infra/gen/chief/frontend_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_docker: exec.Run & {
		$after:  vet_docker
		display: "📦 Generating .docker/ (monorepo skeleton)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			shopt -s globstar nullglob
			mkdir -p .docker/server/docs/docs/api
			mapfile -t files < <(printf '%s\n' ./infra/docker/_tool.cue ./infra/docker/cue/**/*.cue ./infra/gen/chief/docker_project.cue ./infra/gen/chief/server_project.cue ./infra/gen/chief/docs_project.cue ./infra/gen/chief/frontend_project.cue | LC_ALL=C sort -u)
			cue cmd genDocker "${files[@]}"
			"""],
	}

	vet_k8s: exec.Run & {
		$after:  gen_docker
		display: "🔍 Vetting infra/k8s (monorepo)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_k8s: exec.Run & {
		$after:  vet_k8s
		display: "☸️ Generating .k8s/ (monorepo skeleton)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			mkdir -p .k8s/cluster .k8s/git .k8s/data .k8s/gpu .k8s/release/platform .k8s/release/workflow .k8s/release/bots .k8s/release/obs .k8s/stack
			mkdir -p .k8s/stack/{argocd,dagger,crossplane,velero,cilium,gateway,karpenter,external-secrets,kyverno,falco,harbor,cert-manager,keda,knative,knative-bootstrap,alertmanager,grafana,loki,tempo,victoria-metrics,otel-operator,helm-catalog}
			shopt -s globstar nullglob
			mapfile -t files < <(printf '%s\n' ./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue | LC_ALL=C sort -u)
			cue cmd genK8s "${files[@]}"
			"""],
	}

	vet_terraform: exec.Run & {
		$after:  gen_k8s
		display: "🔍 Vetting infra/terraform (monorepo)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/terraform/_tool.cue ./infra/terraform/cue/**/*.cue ./infra/gen/chief/terraform_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_terraform: exec.Run & {
		$after:  vet_terraform
		display: "🌍 Generating .opentofu/ (monorepo skeleton)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			mkdir -p .opentofu/modules .opentofu/environments .opentofu/providers
			shopt -s globstar nullglob
			mapfile -t files < <(printf '%s\n' ./infra/terraform/_tool.cue ./infra/terraform/cue/**/*.cue ./infra/gen/chief/terraform_project.cue | LC_ALL=C sort -u)
			cue cmd genTerraform "${files[@]}"
			"""],
	}

	gen_docs: exec.Run & {
		$after:  gen_terraform
		display: "📚 Generating docs stubs (infra/gen/chief/docs/)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			mkdir -p infra/gen/chief/docs
			shopt -s globstar nullglob
			mapfile -t files < <(printf '%s\n' ./infra/docs/_tool.cue ./infra/docs/cue/*.cue | LC_ALL=C sort -u)
			cue vet "${files[@]}"
			cue cmd genDocs "${files[@]}"
			"""],
	}

	sync_folders: {
		for item in folder_sync {
			"sync-\(item.target)": exec.Run & {
				$after:  gen_docs
				cmd:     "rm -rf \(item.target) && cp -r \(item.source) \(item.target)"
				display: "  → Syncing \(item.source) to \(item.target)"
			}
		}
	}

	final_msg: exec.Run & {
		$after: sync_folders
		cmd:    "echo ✅ genMonorepo: .docker/ + .k8s/ + .opentofu/ + docs stubs + folder sync"
	}
}

// genChief — rice cook: Mint overlays + project-filled gen (requires CHIEF_PROJECT).
command: genChief: {
	apply_docker: exec.Run & {
		display: "🍚 Applying CHIEF overlays (Mint → infra/gen/chief/)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			export RICE_MONO_ROOT="$REPO"
			export PATH="${HOME}/.cargo/bin:${PATH}"
			if [[ -z "${CHIEF_PROJECT:-}" ]]; then
			  echo "error: CHIEF_PROJECT unset — set to custom/<project> (e.g. code-rice.com)" >&2
			  exit 1
			fi
			cargo run -q --manifest-path base/Cargo.toml -p mint --bin mint_overlay_check -- --apply-all
			"""],
	}

	vet_docker: exec.Run & {
		$after:  apply_docker
		display: "🔍 Vetting infra/docker (CHIEF)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/docker/_tool.cue ./infra/docker/cue/**/*.cue ./infra/gen/chief/docker_project.cue ./infra/gen/chief/server_project.cue ./infra/gen/chief/docs_project.cue ./infra/gen/chief/frontend_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_docker: exec.Run & {
		$after:  vet_docker
		display: "📦 Generating .docker/ (CHIEF project)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			shopt -s globstar nullglob
			mkdir -p .docker/server/docs/docs/api
			mapfile -t files < <(printf '%s\n' ./infra/docker/_tool.cue ./infra/docker/cue/**/*.cue ./infra/gen/chief/docker_project.cue ./infra/gen/chief/server_project.cue ./infra/gen/chief/docs_project.cue ./infra/gen/chief/frontend_project.cue | LC_ALL=C sort -u)
			cue cmd genDocker "${files[@]}"
			"""],
	}

	vet_k8s: exec.Run & {
		$after:  gen_docker
		display: "🔍 Vetting infra/k8s (CHIEF)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_k8s: exec.Run & {
		$after:  vet_k8s
		display: "☸️ Generating .k8s/ (CHIEF project)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			mkdir -p .k8s/cluster .k8s/git .k8s/data .k8s/gpu .k8s/release/platform .k8s/release/workflow .k8s/release/bots .k8s/release/obs .k8s/stack
			mkdir -p .k8s/stack/{argocd,dagger,crossplane,velero,cilium,gateway,karpenter,external-secrets,kyverno,falco,harbor,cert-manager,keda,knative,knative-bootstrap,alertmanager,grafana,loki,tempo,victoria-metrics,otel-operator,helm-catalog}
			shopt -s globstar nullglob
			mapfile -t files < <(printf '%s\n' ./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue | LC_ALL=C sort -u)
			cue cmd genK8s "${files[@]}"
			"""],
	}

	vet_terraform: exec.Run & {
		$after:  gen_k8s
		display: "🔍 Vetting infra/terraform (CHIEF)..."
		cmd: ["bash", "-c", """
			set -euo pipefail
			shopt -s globstar nullglob
			files=(./infra/terraform/_tool.cue ./infra/terraform/cue/**/*.cue ./infra/gen/chief/terraform_project.cue)
			cue vet "${files[@]}"
			"""],
	}

	gen_terraform: exec.Run & {
		$after:  vet_terraform
		display: "🌍 Generating .opentofu/ (CHIEF project)"
		cmd: ["bash", "-c", """
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(pwd)}"
			cd "$REPO"
			mkdir -p .opentofu/modules .opentofu/environments .opentofu/providers
			shopt -s globstar nullglob
			mapfile -t files < <(printf '%s\n' ./infra/terraform/_tool.cue ./infra/terraform/cue/**/*.cue ./infra/gen/chief/terraform_project.cue | LC_ALL=C sort -u)
			cue cmd genTerraform "${files[@]}"
			"""],
	}

	sync_folders: {
		for item in folder_sync {
			"sync-\(item.target)": exec.Run & {
				$after:  gen_terraform
				cmd:     "rm -rf \(item.target) && cp -r \(item.source) \(item.target)"
				display: "  → Syncing \(item.source) to \(item.target)"
			}
		}
	}

	final_msg: exec.Run & {
		$after: sync_folders
		cmd:    "echo ✅ genChief: CHIEF overlays applied for ${CHIEF_PROJECT:-unknown}"
	}
}
