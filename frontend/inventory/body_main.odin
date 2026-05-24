// rice body — Odin scans the machine, writes atlas.sys, syncs pixi.toml (one platform).
// Usage (repo root): cd frontend/inventory && odin run body_main.odin -file
//   RICE_MONO_ROOT=/path/to/rice  RICE_ATLAS_OUT=/path/to/rice/atlas.sys
package main

import "core:fmt"
import "core:os"
import "core:strings"
import bi "src"

main :: proc() {
	repo := strings.trim_right(strings.trim_space(os.get_env_alloc("RICE_MONO_ROOT", context.temp_allocator)), "/")
	if len(repo) == 0 {
		repo = "."
	}
	atlas_out := os.get_env_alloc("RICE_ATLAS_OUT", context.temp_allocator)
	if len(atlas_out) == 0 {
		if cfg := #config(RICE_ATLAS_OUT, ""); len(cfg) > 0 {
			atlas_out = cfg
		} else {
			atlas_out = fmt.tprintf("%s/atlas.sys", repo)
		}
	}
	if !bi.body_materialize(repo, atlas_out) {
		fmt.eprintf("body: materialize failed (atlas=%s repo=%s)\n", atlas_out, repo)
		os.exit(1)
	}
	fmt.printf("body: atlas.sys → %s\n", atlas_out)
	fmt.printf("body: pixi.toml platform=%s (run pixi install next)\n", bi.detect_pixi_platform())
}
