package configs

import (
	"list"
	root "github.com/rice-rob-inn-com-ent/rice/infra/configs/root"
	docker "github.com/rice-rob-inn-com-ent/rice/infra/configs/docker"
	github "github.com/rice-rob-inn-com-ent/rice/infra/configs/github"
	kubernetes "github.com/rice-rob-inn-com-ent/rice/infra/configs/kubernetes"
	terraform "github.com/rice-rob-inn-com-ent/rice/infra/configs/terraform"
	ide "github.com/rice-rob-inn-com-ent/rice/infra/configs/ide"
	reuse "github.com/rice-rob-inn-com-ent/rice/infra/configs/reuse"
	svc "github.com/rice-rob-inn-com-ent/rice/infra/configs/service"
	basecfg "github.com/rice-rob-inn-com-ent/rice/infra/configs/base"
	frontend "github.com/rice-rob-inn-com-ent/rice/infra/configs/frontend"
	fn "github.com/rice-rob-inn-com-ent/rice/infra/configs/function"
	infracfg "github.com/rice-rob-inn-com-ent/rice/infra/configs/infra"
)

order: list.Concat([
	root.paths,
	docker.paths,
	github.paths,
	kubernetes.paths,
	terraform.paths,
	ide.paths,
	reuse.paths,
	svc.paths,
	basecfg.paths,
	frontend.paths,
	fn.paths,
	infracfg.paths,
])

king_content: root.content & docker.content & github.content & kubernetes.content & terraform.content & ide.content & reuse.content & svc.content & basecfg.content & frontend.content & fn.content & infracfg.content

king_folder_file_outputs: list.Concat([
	root.folder_outputs,
	docker.folder_outputs,
	github.folder_outputs,
	kubernetes.folder_outputs,
	terraform.folder_outputs,
	ide.folder_outputs,
	reuse.folder_outputs,
	svc.folder_outputs,
	basecfg.folder_outputs,
	frontend.folder_outputs,
	fn.folder_outputs,
	infracfg.folder_outputs,
])
