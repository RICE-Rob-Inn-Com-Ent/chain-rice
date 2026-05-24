// Entry for `odin run .` from frontend/inventory — full atlas.sys via bard_inventory probes.
package main

import "core:fmt"
import "core:os"
import bi "src"

main :: proc() {
	out := #config(RICE_ATLAS_OUT, "atlas.sys")
	repo := os.get_env("RICE_MONO_ROOT", ".")
	inv_dir := fmt.tprintf("%s/frontend/inventory", repo)
	if !bi.run_full_inventory_atlas(inv_dir) {
		fmt.eprintf("atlas: run_full_inventory_atlas failed\n")
		os.exit(1)
	}
	gen_path := fmt.tprintf("%s/atlas.sys", inv_dir)
	if out != gen_path {
		data, err := os.read_entire_file(gen_path, context.temp_allocator)
		if err != os.ERROR_NONE {
			fmt.eprintf("atlas: read %s failed\n", gen_path)
			os.exit(1)
		}
		if os.write_entire_file_from_bytes(out, data) != os.ERROR_NONE {
			fmt.eprintf("atlas: write %s failed\n", out)
			os.exit(1)
		}
	}
	fmt.printf("atlas.sys at %s\n", out)
}
