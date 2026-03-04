package config

// =============================================================================
// KINGS ROOT (STATIC)
// =============================================================================
//
// This file is the single source of truth for:
//   1. Root config files at 🫅KING (pixi.toml, .editorconfig, Justfile, etc.)
//   2. Static .code-workspace / rice.code-workspace for the KING folder.
//
// Part 1 – Root files:
//   - order:        List of file paths in the order they are written.
//   - king_content: Map from each path to its full file content (string).
//   - king_outputs: Derived list of {path, content} for manifest.outputs.
//
// Part 2 – Workspace for rice.code-workspace (STATIC, BEZ SEZONÓW):
//   - workspace:    VS Code / Cursor workspace object (folders, settings,
//                   extensions). This is what `.envrc` exports to
//                     rice.code-workspace  via:
//                       cue export infra/config/king_root_files.cue -e 'king_content["rice.code-workspace"]' --out text
//
// Manifest (infra/manifest.cue) + cue cmd gen (manifest_tool.cue) generują pliki roota z order i king_content
// (including the string version of `rice.code-workspace` stored in
// king_content["rice.code-workspace"]).
// =============================================================================

// workspace is no longer defined here – we export rice.code-workspace
// directly from king_content["rice.code-workspace"] using `cue export --out text`.

// order: File paths at repository root, in generation order.
// First entry is pixi.toml (install/toolchain entry point); rest follow logically.
order: [
	"pixi.toml",
	".convco.toml",
	".editorconfig",
	".envrc",
	".gitattributes",
	".gitignore",
	".cursorignore",
	".vale.ini",
	"cliff.toml",
	"dagger.json",
	"Justfile",
	"lefthook.yml",
	"LICENSE.md",
	"CODE_OF_CONDUCT.md",
	"CONTRIBUTING.md",
	"SECURITY.md",
	"README.md",
	"renovate.json",
	"rice.code-workspace",
	"taplo.toml",
	"vhs.tape",
	".sops.yaml",
	".dockerignore",
	".markdownlint.json",
	".tflint.hcl",
	"atlas.hcl",
	"docker-compose.yml",
]

// king_content: Full content for each root file. Keys must match order entries.
// Values are strings (often multi-line with """ ... """). Do not edit generated
// files on disk; change here and regenerate.
king_content: {
	// --- Toolchain & install (first in order) ---
	"pixi.toml": """
		[project]
		name = "rice"
		version = "0.1.0"
		description = "Rice tool management system"
		channels = ["conda-forge", "modular-channels"]
		platforms = ["linux-64", "osx-arm64", "osx-64", "win-64"]

		[dependencies]
		cue = "0.9"
		timoni = "0.22"
		dagger = "0.13"
		gomplate = "3.11"
		fvm = "3.1"
		spider = "4.2"
		elixir = "1.18"
		erlang = "27"
		lexical = "0.7"
		go = "1.23"
		govulncheck = "1.1"
		golangci-lint = "1.60"
		gofumpt = "0.7"
		air = "1.52"
		ghc = "9.6"
		stack = "2.15"
		haskell-language-server = "2.9"
		fourmolu = "0.14"
		hlint = "3.8"
		stan = "0.0.1"
		markdownlint-cli2 = "0.13"
		mkdocs = "1.6"
		mkdocs-material = "9.7"
		python = "3.13"
		mojo = "0.26.1"
		uv = "0.5"
		ruff = "0.8"
		mypy = "1.13"
		pytest = "8"
		bandit = "1.8"
		bun = "1.2"
		biome = "1.9"
		rust = "1.84"
		cargo = "1.84"
		bacon = "2.18"
		rust-analyzer = "2025.01"
		clippy = "1.84"
		rustfmt = "1.84"
		cargo-expand = "0.6"
		cargo-audit = "0.20"
		cargo-nextest = "0.9"
		terraform = "1.10"
		terraform-ls = "0.34"
		tflint = "0.55"
		checkov = "3.2"
		trivy = "0.58"
		zig = "0.13.0"
		zls = "0.13.0"
		buf = "2.5"
		ruby = "3.4"
		solargraph = "0.51"
		awscli = "2.22"
		google-cloud-sdk = "507"
		azure-cli = "2.68"
		semgrep = "1.95"
		docker = "29"
		cosign = "2.4"
		kubernetes = "1.32"
		helm = "3.16"
		kubectl = "1.32"
		k9s = "0.32"
		atlas = "0.30"
		sqlc = "1.27"
		jq = "1.7"
		yq = "4.44"
		just = "1.42"
		direnv = "3.2"
		watchexec = "2.1"
		inotify-tools = "4.23"
		lychee = "0.15"
		vale = "3.4"
		openapi-generator-cli = "7.8"
		swagger-cli = "4.0"
		vhs = "0.7"
		ttyd = "1.7"
		ffmpeg = "7.0"
		curl = "8.0"
		grclib = "0.20"
		foundry = "0.2"
		anchor-cli = "0.30"
		substrate-contracts-node = "0.40"
		cargo-stylus = "0.5"
		stellar-cli = "21.5"
		convco = "0.6"
		reuse = "4.0"
		git-cliff = "2.4"
		lefthook = "1.10"
		sops = "3.9"
		age = "1.2"
		trufflehog = "3.82"
		axe-core-cli = "4.10"
		redoc-cli = "0.13"
		tailwindcss = "4.0"
		lightningcss = "1.28"
		"""

	// --- Commit conventions & changelog ---
	".convco.toml": """
		[commit]
		types = ["feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore"]
		"""

	// --- Editor & formatting (shared across IDEs) ---
	".editorconfig": """
		root = true

		[*]
		charset = utf-8
		end_of_line = lf
		insert_final_newline = true
		trim_trailing_whitespace = true

		[*.{py,js,ts,jsx,tsx}]
		indent_style = space
		indent_size = 2
		max_line_length = 79

		[*.{go,rust}]
		indent_style = space
		indent_size = 4
		max_line_length = 120

		[*.{yaml,yml}]
		indent_style = space
		indent_size = 2

		[*.{json,jsonc}]
		indent_style = space
		indent_size = 2

		[*.md]
		trim_trailing_whitespace = false

		[*.{tf,tfvars}]
		indent_style = space
		indent_size = 2

		[*.{proto}]
		indent_style = space
		indent_size = 2

		[*.{dockerfile,Dockerfile}]
		indent_style = space
		indent_size = 2

		[*.{toml}]
		indent_style = space
		indent_size = 2

		[*.{dart}]
		indent_style = space
		indent_size = 2
		max_line_length = 120

		[*.{erl,ex}]
		indent_style = space
		indent_size = 2
		max_line_length = 120
		"""

	// --- Direnv: env loading for repo root ---
	".envrc": """
		# shellcheck shell=bash
		# cSpell:ignore DIRENV direnv dotenv
		# ==============================================================================
		# DIRENV CONFIGURATION - Rice Monorepo
		# ==============================================================================
		# This file configures direnv (https://direnv.net/) to automatically load
		# development environment variables when entering this directory.
		#
		# Usage:
		#   1. Install direnv: https://direnv.net/docs/installation.html
		#   2. Allow this file: `direnv allow` (first time only)
		# ==============================================================================
		strict_env
		log_status "⏳ Loading development environment..."
		"""

	// --- Git: attributes and ignore ---
	".gitattributes": """
		* text=auto
		*.go text eol=lf diff=go
		*.py text eol=lf diff=python
		*.rs text eol=lf diff=rust
		*.toml text eol=lf
		*.js *.jsx *.ts *.tsx *.mjs *.cjs text eol=lf
		*.html *.css *.scss *.yaml *.yml *.json *.jsonc text eol=lf
		*.md text eol=lf diff=markdown
		Dockerfile *.dockerfile .dockerignore text eol=lf
		*.tf *.tfvars text eol=lf
		*.sh *.bash *.zsh *.fish text eol=lf
		LICENSE README *README* text eol=lf
		*.png *.jpg *.jpeg *.gif *.ico binary
		*.svg text
		.gitattributes .gitignore .github .vscode .idea export-ignore
		"""

	".gitignore": """
		node_modules/
		__pycache__/
		*.py[cod]
		.venv/
		venv/
		target/
		dist/
		build/
		.pytest_cache/
		coverage/
		.env
		.env.local
		.env.*.local
		.terraform/
		*.tfstate
		*.tfstate.*
		.github/instructions/
		"""

	// --- Cursor: ignore patterns (indexing / AI)
	".cursorignore": """
		# ============================================================================
		# CURSOR IGNORE PATTERNS
		# ============================================================================
		# Files and directories that Cursor should ignore during codebase indexing
		# and AI features. Uses .gitignore syntax.
		# ============================================================================

		# Build outputs
		**/dist/
		**/build/
		**/target/
		**/out/
		**/.next/
		**/.nuxt/
		**/.output/
		**/.cache/
		**/node_modules/
		**/.venv/
		**/venv/
		**/__pycache__/
		**/.pytest_cache/
		**/.mypy_cache/
		**/.ruff_cache/

		# IDE
		**/.idea/
		**/.vscode/
		**/.cursor/
		**/.vs/

		# OS
		**/.DS_Store
		**/Thumbs.db
		**/.directory

		# Logs
		**/*.log
		**/logs/
		**/.logs/

		# Temporary files
		**/*.tmp
		**/*.temp
		**/.tmp/
		**/.temp/

		# Database
		**/*.db
		**/*.sqlite
		**/*.sqlite3

		# Environment
		**/.env
		**/.env.local
		**/.env.*.local
		**/.secrets/

		# Generated files
		**/generated/
		**/gen/
		**/*_generated.*
		**/*.pb.go
		**/*.pb.py
		**/*_pb2.py
		**/*_pb2_grpc.py

		# Coverage
		**/coverage/
		**/.coverage
		**/htmlcov/
		**/.nyc_output/

		# Documentation builds
		**/_build/
		**/.doctrees/
		**/site/

		# Large binary files
		**/*.zip
		**/*.tar.gz
		**/*.rar
		**/*.7z
		**/*.iso
		**/*.dmg
		**/*.deb
		**/*.rpm

		# Media files (usually too large for indexing)
		**/*.mp4
		**/*.avi
		**/*.mov
		**/*.mkv
		**/*.mp3
		**/*.wav
		**/*.flac

		# Archives
		**/*.jar
		**/*.war
		**/*.ear

		# Lock files (usually too large and not useful for AI)
		**/package-lock.json
		**/Cargo.lock

		# Vendor dependencies
		**/vendor/
		**/third_party/
		**/external/

		# Test outputs
		**/.pytest_cache/
		**/.tox/
		**/.hypothesis/

		# Profiling
		**/*.prof
		**/*.pprof

		# Compiled
		**/*.class
		**/*.o
		**/*.so
		**/*.dylib
		**/*.dll
		**/*.exe
		"""

	// --- Prose linting (Vale) ---
	".vale.ini": """
		StylesPath = .vale/styles
		MinAlertLevel = suggestion
		Vocab = Rice

		[formats]
		markdown = md
		*.md = md

		[Rice]
		BasedOnStyles = Google, write-good
		Packages = Microsoft, write-good
		"""

	// --- Changelog from conventional commits (git-cliff) ---
	"cliff.toml": """
		# git-cliff – changelog z konwencjonalnych commitów (convco)
		# Użycie: pixi run git-cliff [--latest] [--unreleased] -o CHANGELOG.md

		[changelog]
		header = "\n# Changelog\n\nWszystkie istotne zmiany w projekcie są dokumentowane w tym pliku.\n\n"
		footer = "<!-- generated by git-cliff -->\n"
		trim = true

		[git]
		commit_parsers = [
		    { pattern = "^feat", group = "Features" },
		    { pattern = "^fix", group = "Bug Fixes" },
		    { pattern = "^doc", group = "Documentation" },
		    { pattern = "^chore\\(release\\)", skip = true },
		    { pattern = "^chore", group = "Miscellaneous" },
		]
		"""

	"dagger.json": "{}"

	// --- Just: tasks (install, config-workspace, …) ---
	"Justfile": """
		# The Rice Framework - Emoji-Driven Orchestration
		# Senior Polyglot Architect Implementation
		# Root config and dotfolders are generated from CUE (infra/config, cue cmd gen). Do not edit by hand.

		set shell := ["bash", "-cu"]

		default:
		    @just --list

		install:
		    @bash -c 'pixi install || (echo "Run: curl -fsSL https://pixi.sh/install.sh | sh" && exit 1)'

		config-workspace:
		    @cue cmd gen ./infra
		"""

	// --- Git hooks (lefthook): pre-commit, commit-msg ---
	"lefthook.yml": """
		pre-commit:
		  parallel: true
		  commands:
		    python-lint:
		      root: "."
		      run: pixi run ruff check python/ && pixi run ruff format --check python/
		    biome:
		      root: "."
		      run: pixi run biome check --write .
		    convco:
		      run: pixi run convco check --no-version-restriction < {1}
		      stage_fixed: true

		commit-msg:
		  commands:
		    convco:
		      run: pixi run convco check --no-version-restriction < {1}
		      stage_fixed: true
		"""

	"LICENSE.md": """
		<!-- markdownlint-disable MD029 -->
		# GNU AFFERO GENERAL PUBLIC LICENSE

		                       Version 3, 19 November 2007

		 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
		 Everyone is permitted to copy and distribute verbatim copies
		 of this license document, but changing it is not allowed.

		                            Preamble

		  The GNU Affero General Public License is a free, copyleft license for
		software and other kinds of works, specifically designed to ensure
		cooperation with the community in the case of network server software.

		  The licenses for most software and other practical works are designed
		to take away your freedom to share and change the works.  By contrast,
		our General Public Licenses are intended to guarantee your freedom to
		share and change all versions of a program--to make sure it remains free
		software for all its users.

		  When we speak of free software, we are referring to freedom, not
		price.  Our General Public Licenses are designed to make sure that you
		have the freedom to distribute copies of free software (and charge for
		them if you wish), that you receive source code or can get it if you
		want it, that you can change the software or use pieces of it in new
		free programs, and that you know you can do these things.

		  Developers that use our General Public Licenses protect your rights
		with two steps: (1) assert copyright on the software, and (2) offer
		you this License which gives you legal permission to copy, distribute
		and/or modify the software.

		  A secondary benefit of defending all users' freedom is that
		improvements made in alternate versions of the program, if they
		receive widespread use, become available for other developers to
		incorporate.  Many developers of free software are heartened and
		encouraged by the resulting cooperation.  However, in the case of
		software used on network servers, this result may fail to come about.
		The GNU General Public License permits making a modified version and
		letting the public access it on a server without ever releasing its
		source code to the public.

		  The GNU Affero General Public License is designed specifically to
		ensure that, in such cases, the modified source code becomes available
		to the community.  It requires the operator of a network server to
		provide the source code of the modified version running there to the
		users of that server.  Therefore, public use of a modified version, on
		a publicly accessible server, gives the public access to the source
		code of the modified version.

		  An older license, called the Affero General Public License and
		published by Affero, was designed to accomplish similar goals.  This is
		a different license, not a version of the Affero GPL, but Affero has
		released a new version of the Affero GPL which permits relicensing under
		this license.

		  The precise terms and conditions for copying, distribution and
		modification follow.

		                       TERMS AND CONDITIONS

		  0. Definitions.

		  "This License" refers to version 3 of the GNU Affero General Public License.

		  "Copyright" also means copyright-like laws that apply to other kinds of
		works, such as semiconductor masks.

		  "The Program" refers to any copyrightable work licensed under this
		License.  Each licensee is addressed as "you".  "Licensees" and
		"recipients" may be individuals or organizations.

		  To "modify" a work means to copy from or adapt all or part of the work
		in a fashion requiring copyright permission, other than the making of an
		exact copy.  The resulting work is called a "modified version" of the
		earlier work or a work "based on" the earlier work.

		  A "covered work" means either the unmodified Program or a work based
		on the Program.

		  To "propagate" a work means to do anything with it that, without
		permission, would make you directly or secondarily liable for
		infringement under applicable copyright law, except executing it on a
		computer or modifying a private copy.  Propagation includes copying,
		distribution (with or without modification), making available to the
		public, and in some countries other activities as well.

		  To "convey" a work means any kind of propagation that enables other
		parties to make or receive copies.  Mere interaction with a user through
		a computer network, with no transfer of a copy, is not conveying.

		  An interactive user interface displays "Appropriate Legal Notices"
		to the extent that it includes a convenient and prominently visible
		feature that (1) displays an appropriate copyright notice, and (2)
		tells the user that there is no warranty for the work (except to the
		extent that warranties are provided), that licensees may convey the
		work under this License, and how to view a copy of this License.  If
		the interface presents a list of user commands or options, such as a
		menu, a prominent item in the list meets this criterion.

		  1. Source Code.

		  The "source code" for a work means the preferred form of the work
		for making modifications to it.  "Object code" means any non-source
		form of a work.

		  A "Standard Interface" means an interface that either is an official
		standard defined by a recognized standards body, or, in the case of
		interfaces specified for a particular programming language, one that
		is widely used among developers working in that language.

		  The "System Libraries" of an executable work include anything, other
		than the work as a whole, that (a) is included in the normal form of
		packaging a Major Component, but which is not part of that Major
		Component, and (b) serves only to enable use of the work with that
		Major Component, or to implement a Standard Interface for which an
		implementation is available to the public in source code form.  A
		"Major Component", in this context, means a major essential component
		(kernel, window system, and so on) of the specific operating system
		(if any) on which the executable work runs, or a compiler used to
		produce the work, or an object code interpreter used to run it.

		  The "Corresponding Source" for a work in object code form means all
		the source code needed to generate, install, and (for an executable
		work) run the object code and to modify the work, including scripts to
		control those activities.  However, it does not include the work's
		System Libraries, or general-purpose tools or generally available free
		programs which are used unmodified in performing those activities but
		which are not part of the work.  For example, Corresponding Source
		includes interface definition files associated with source files for
		the work, and the source code for shared libraries and dynamically
		linked subprograms that the work is specifically designed to require,
		such as by intimate data communication or control flow between those
		subprograms and other parts of the work.

		  The Corresponding Source need not include anything that users
		can regenerate automatically from other parts of the Corresponding
		Source.

		  The Corresponding Source for a work in source code form is that
		same work.

		  2. Basic Permissions.

		  All rights granted under this License are granted for the term of
		copyright on the Program, and are irrevocable provided the stated
		conditions are met.  This License explicitly affirms your unlimited
		permission to run the unmodified Program.  The output from running a
		covered work is covered by this License only if the output, given its
		content, constitutes a covered work.  This License acknowledges your
		rights of fair use or other equivalent, as provided by copyright law.

		  You may make, run and propagate covered works that you do not
		convey, without conditions so long as your license otherwise remains
		in force.  You may convey covered works to others for the sole purpose
		of having them make modifications exclusively for you, or provide you
		with facilities for running those works, provided that you comply with
		the terms of this License in conveying all material for which you do
		not control copyright.  Those thus making or running the covered works
		for you must do so exclusively on your behalf, under your direction
		and control, on terms that prohibit them from making any copies of
		your copyrighted material outside their relationship with you.

		  Conveying under any other circumstances is permitted solely under
		the conditions stated below.  Sublicensing is not allowed; section 10
		makes it unnecessary.

		  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

		  No covered work shall be deemed part of an effective technological
		measure under any applicable law fulfilling obligations under article
		11 of the WIPO copyright treaty adopted on 20 December 1996, or
		similar laws prohibiting or restricting circumvention of such
		measures.

		  When you convey a covered work, you waive any legal power to forbid
		circumvention of technological measures to the extent such circumvention
		is effected by exercising rights under this License with respect to
		the covered work, and you disclaim any intention to limit operation or
		modification of the work as a means of enforcing, against the work's
		users, your or third parties' legal rights to forbid circumvention of
		technological measures.

		  4. Conveying Verbatim Copies.

		  You may convey verbatim copies of the Program's source code as you
		receive it, in any medium, provided that you conspicuously and
		appropriately publish on each copy an appropriate copyright notice;
		keep intact all notices stating that this License and any
		non-permissive terms added in accord with section 7 apply to the code;
		keep intact all notices of the absence of any warranty; and give all
		recipients a copy of this License along with the Program.

		  You may charge any price or no price for each copy that you convey,
		and you may offer support or warranty protection for a fee.

		  5. Conveying Modified Source Versions.

		  You may convey a work based on the Program, or the modifications to
		produce it from the Program, in the form of source code under the
		terms of section 4, provided that you also meet all of these conditions:

		    a) The work must carry prominent notices stating that you modified
		    it, and giving a relevant date.

		    b) The work must carry prominent notices stating that it is
		    released under this License and any conditions added under section
		    7.  This requirement modifies the requirement in section 4 to
		    "keep intact all notices".

		    c) You must license the entire work, as a whole, under this
		    License to anyone who comes into possession of a copy.  This
		    License will therefore apply, along with any applicable section 7
		    additional terms, to the whole of the work, and all its parts,
		    regardless of how they are packaged.  This License gives no
		    permission to license the work in any other way, but it does not
		    invalidate such permission if you have separately received it.

		    d) If the work has interactive user interfaces, each must display
		    Appropriate Legal Notices; however, if the Program has interactive
		    interfaces that do not display Appropriate Legal Notices, your
		    work need not make them do so.

		  6. Conveying Non-Source Forms.

		  You may convey a covered work in object code form under the terms
		of sections 4 and 5, provided that you also convey the
		machine-readable Corresponding Source under the terms of this License,
		in one of these ways:

		    a) Convey the object code in, or embodied in, a physical product
		    (including a physical distribution medium), accompanied by the
		    Corresponding Source fixed on a durable physical medium
		    customarily used for software interchange.

		    b) Convey the object code in, or embodied in, a physical product
		    (including a physical distribution medium), accompanied by a
		    written offer, valid for at least three years and valid for as
		    long as you offer spare parts or customer support for that product
		    model, to give anyone who possesses the object code either (1) a
		    copy of the Corresponding Source for all the software in the
		    product that is covered by this License, on a durable physical
		    medium customarily used for software interchange, for a price no
		    more than your reasonable cost of physically performing this
		    conveying of source, or (2) access to copy the
		    Corresponding Source from a network server at no charge.

		    c) Convey individual copies of the object code with a copy of the
		    written offer to provide the Corresponding Source.  This
		    alternative is allowed only occasionally and noncommercially, and
		    only if you received the object code with such an offer, in accord
		    with subsection 6b.

		    d) Convey the object code by offering access from a designated
		    place (gratis or for a charge), and offer equivalent access to the
		    Corresponding Source in the same way through the same place at no
		    further charge.  You need not require recipients to copy the
		    Corresponding Source along with the object code.  If the place to
		    copy the object code is a network server, the Corresponding Source
		    may be on a different server (operated by you or a third party)
		    that supports equivalent copying facilities, provided you maintain
		    clear directions next to the object code saying where to find the
		    Corresponding Source.  Regardless of what server hosts the
		    Corresponding Source, you remain obligated to ensure that it is
		    available for as long as needed to satisfy these requirements.

		    e) Convey the object code using peer-to-peer transmission, provided
		    you inform other peers where the object code and Corresponding
		    Source of the work are being offered to the general public at no
		    charge under subsection 6d.

		  A separable portion of the object code, whose source code is excluded
		from the Corresponding Source as a System Library, need not be
		included in conveying the object code work.

		  A "User Product" is either (1) a "consumer product", which means any
		tangible personal property which is normally used for personal, family,
		or household purposes, or (2) anything designed or sold for incorporation
		into a dwelling.  In determining whether a product is a consumer product,
		doubtful cases shall be resolved in favor of coverage.  For a particular
		product received by a particular user, "normally used" refers to a
		typical or common use of that class of product, regardless of the status
		of the particular user or of the way in which the particular user
		actually uses, or expects or is expected to use, the product.  A product
		is a consumer product regardless of whether the product has substantial
		commercial, industrial or non-consumer uses, unless such uses represent
		the only significant mode of use of the product.

		  "Installation Information" for a User Product means any methods,
		procedures, authorization keys, or other information required to install
		and execute modified versions of a covered work in that User Product from
		a modified version of its Corresponding Source.  The information must
		suffice to ensure that the continued functioning of the modified object
		code is in no case prevented or interfered with solely because
		modification has been made.

		  If you convey an object code work under this section in, or with, or
		specifically for use in, a User Product, and the conveying occurs as
		part of a transaction in which the right of possession and use of the
		User Product is transferred to the recipient in perpetuity or for a
		fixed term (regardless of how the transaction is characterized), the
		Corresponding Source conveyed under this section must be accompanied
		by the Installation Information.  But this requirement does not apply
		if neither you nor any third party retains the ability to install
		modified object code on the User Product (for example, the work has
		been installed in ROM).

		  The requirement to provide Installation Information does not include a
		requirement to continue to provide support service, warranty, or updates
		for a work that has been modified or installed by the recipient, or for
		the User Product in which it has been modified or installed.  Access to a
		network may be denied when the modification itself materially and
		adversely affects the operation of the network or violates the rules and
		protocols for communication across the network.

		  Corresponding Source conveyed, and Installation Information provided,
		in accord with this section must be in a format that is publicly
		documented (and with an implementation available to the public in
		source code form), and must require no special password or key for
		unpacking, reading or copying.

		  7. Additional Terms.

		  "Additional permissions" are terms that supplement the terms of this
		License by making exceptions from one or more of its conditions.
		Additional permissions that are applicable to the entire Program shall
		be treated as though they were included in this License, to the extent
		that they are valid under applicable law.  If additional permissions
		apply only to part of the Program, that part may be used separately
		under those permissions, but the entire Program remains governed by
		this License without regard to the additional permissions.

		  When you convey a copy of a covered work, you may at your option
		remove any additional permissions from that copy, or from any part of
		it.  (Additional permissions may be written to require their own
		removal in certain cases when you modify the work.)  You may place
		additional permissions on material, added by you to a covered work,
		for which you have or can give appropriate copyright permission.

		  Notwithstanding any other provision of this License, for material you
		add to a covered work in accord with this section, you may (if authorized
		by the copyright holders of that material) supplement the terms of this
		License with terms:

		    a) Disclaiming warranty or limiting liability differently from the
		    terms of sections 15 and 16 of this License; or

		    b) Requiring preservation of specified reasonable legal notices or
		    author attributions in that material or in the Appropriate Legal
		    Notices displayed by works containing it; or

		    c) Prohibiting misrepresentation of the origin of that material, or
		    requiring that modified versions of such material be marked in
		    reasonable ways as different from the original version; or

		    d) Limiting the use for publicity purposes of names of licensors or
		    authors of the material; or

		    e) Declining to grant rights under trademark law for use of some
		    trade names, trademarks, or service marks; or

		    f) Requiring indemnification of licensors and authors of that
		    material by anyone who conveys the material (or modified versions of
		    it) with contractual assumptions of liability to the recipient, for
		    any liability that these contractual assumptions directly impose on
		    those licensors and authors.

		  All other non-permissive additional terms are considered "further
		restrictions" within the meaning of section 10.  If the Program as you
		received it, or any part of it, contains a notice stating that it is
		governed by this License along with a term that is a further
		restriction, you may remove that term.  If a license document contains
		a further restriction but permits relicensing or conveying under this
		License, you may add to a covered work material governed by the terms
		of that license document, provided that the further restriction does
		not survive such relicensing or conveying.

		  If you add terms to a covered work in accord with this section, you
		must place, in the relevant source files, a statement of the
		additional terms that apply to those files, or a notice indicating
		where to find the applicable terms.

		  Additional terms, permissive or non-permissive, may be stated in the
		form of a separately written license, or stated as exceptions;
		the above requirements apply either way.

		  8. Termination.

		  You may not propagate or modify a covered work except as expressly
		provided under this License.  Any attempt otherwise to propagate or
		modify it is void, and will automatically terminate your rights under
		this License (including any patent licenses granted under the third
		paragraph of section 11).

		  However, if you cease all violation of this License, then your
		license from a particular copyright holder is reinstated (a)
		provisionally, unless and until the copyright holder explicitly and
		finally terminates your license, and (b) permanently, if the copyright
		holder fails to notify you of the violation by some reasonable means
		prior to 60 days after the cessation.

		  Moreover, your license from a particular copyright holder is
		reinstated permanently if the copyright holder notifies you of the
		violation by some reasonable means, this is the first time you have
		received notice of violation of this License (for any work) from that
		copyright holder, and you cure the violation prior to 30 days after
		your receipt of the notice.

		  Termination of your rights under this section does not terminate the
		licenses of parties who have received copies or rights from you under
		this License.  If your rights have been terminated and not permanently
		reinstated, you do not qualify to receive new licenses for the same
		material under section 10.

		  9. Acceptance Not Required for Having Copies.

		  You are not required to accept this License in order to receive or
		run a copy of the Program.  Ancillary propagation of a covered work
		occurring solely as a consequence of using peer-to-peer transmission
		to receive a copy likewise does not require acceptance.  However,
		nothing other than this License grants you permission to propagate or
		modify any covered work.  These actions infringe copyright if you do
		not accept this License.  Therefore, by modifying or propagating a
		covered work, you indicate your acceptance of this License to do so.

		  10. Automatic Licensing of Downstream Recipients.

		  Each time you convey a covered work, the recipient automatically
		receives a license from the original licensors, to run, modify and
		propagate that work, subject to this License.  You are not responsible
		for enforcing compliance by third parties with this License.

		  An "entity transaction" is a transaction transferring control of an
		organization, or substantially all assets of one, or subdividing an
		organization, or merging organizations.  If propagation of a covered
		work results from an entity transaction, each party to that
		transaction who receives a copy of the work also receives whatever
		licenses to the work the party's predecessor in interest had or could
		give under the previous paragraph, plus a right to possession of the
		Corresponding Source of the work from the predecessor in interest, if
		the predecessor has it or can get it with reasonable efforts.

		  You may not impose any further restrictions on the exercise of the
		rights granted or affirmed under this License.  For example, you may
		not impose a license fee, royalty, or other charge for exercise of
		rights granted under this License, and you may not initiate litigation
		(including a cross-claim or counterclaim in a lawsuit) alleging that
		any patent claim is infringed by making, using, selling, offering for
		sale, or importing the Program or any portion of it.

		  11. Patents.

		  A "contributor" is a copyright holder who authorizes use under this
		License of the Program or a work on which the Program is based.  The
		work thus licensed is called the contributor's "contributor version".

		  A contributor's "essential patent claims" are all patent claims
		owned or controlled by the contributor, whether already acquired or
		hereafter acquired, that would be infringed by some manner, permitted
		by this License, of making, using, or selling its contributor version,
		but do not include claims that would be infringed only as a
		consequence of further modification of the contributor version.  For
		purposes of this definition, "control" includes the right to grant
		patent sublicenses in a manner consistent with the requirements of
		this License.

		  Each contributor grants you a non-exclusive, worldwide, royalty-free
		patent license under the contributor's essential patent claims, to
		make, use, sell, offer for sale, import and otherwise run, modify and
		propagate the contents of its contributor version.

		  In the following three paragraphs, a "patent license" is any express
		agreement or commitment, however denominated, not to enforce a patent
		(such as an express permission to practice a patent or covenant not to
		sue for patent infringement).  To "grant" such a patent license to a
		party means to make such an agreement or commitment not to enforce a
		patent against the party.

		  If you convey a covered work, knowingly relying on a patent license,
		and the Corresponding Source of the work is not available for anyone
		to copy, free of charge and under the terms of this License, through a
		publicly available network server or other readily accessible means,
		then you must either (1) cause the Corresponding Source to be so
		available, or (2) arrange to deprive yourself of the benefit of the
		patent license for this particular work, or (3) arrange, in a manner
		consistent with the requirements of this License, to extend the patent
		license to downstream recipients.  "Knowingly relying" means you have
		actual knowledge that, but for the patent license, your conveying the
		covered work in a country, or your recipient's use of the covered work
		in a country, would infringe one or more identifiable patents in that
		country that you have reason to believe are valid.

		  If you convey a covered work, knowingly relying on a patent license,
		and the Corresponding Source of the work is not available for anyone
		to copy, free of charge and under the terms of this License, through a
		publicly available network server or other readily accessible means,
		then you must either (1) cause the Corresponding Source to be so
		available, or (2) arrange to deprive yourself of the benefit of the
		patent license for this particular work, or (3) arrange, in a manner
		consistent with the requirements of this License, to extend the patent
		license to downstream recipients.  "Knowingly relying" means you have
		actual knowledge that, but for the patent license, your conveying the
		covered work in a country, or your recipient's use of the covered work
		in a country, would infringe one or more identifiable patents in that
		country that you have reason to believe are valid.

		  If, pursuant to or in connection with a single transaction or
		arrangement, you convey, or propagate by procuring conveyance of, a
		covered work, and grant a patent license to some of the parties
		receiving the covered work authorizing them to use, propagate, modify
		or convey a specific copy of the covered work, then the patent license
		you grant is automatically extended to all recipients of the covered
		work and works based on it.

		  A patent license is "discriminatory" if it does not include within
		the scope of its coverage, prohibits the exercise of, or is
		conditioned on the non-exercise of one or more of the rights that are
		specifically granted under this License.  You may not convey a covered
		work if you are a party to an arrangement with a third party that is
		in the business of distributing software, under which you make payment
		to the third party based on the extent of your activity of conveying
		the work, and under which the third party grants, to any of the
		parties who would receive the covered work from you, a discriminatory
		patent license (a) in connection with copies of the covered work
		conveyed by you (or copies made from those copies), or (b) primarily
		for and in connection with specific products or compilations that
		contain the covered work, unless you entered into that arrangement,
		or that patent license was granted, prior to 28 March 2007.

		  Nothing in this License shall be construed as excluding or limiting
		any implied license or other defenses to infringement that may
		otherwise be available to you under applicable patent law.

		  12. No Surrender of Others' Freedom.

		  If conditions are imposed on you (whether by court order, agreement or
		otherwise) that contradict the conditions of this License, they do not
		excuse you from the conditions of this License.  If you cannot convey a
		covered work so as to satisfy simultaneously your obligations under this
		License and any other pertinent obligations, then as a consequence you may
		not convey it at all.  For example, if you agree to terms that obligate you
		to collect a royalty for further conveying from those to whom you convey
		the Program, the only way you could satisfy both those terms and this
		License would be to refrain entirely from conveying the Program.

		  13. Remote Network Interaction; Use with the GNU General Public License.

		  Notwithstanding any other provision of this License, if you modify the
		Program, your modified version must prominently offer all users
		interacting with it remotely through a computer network (if your version
		supports such interaction) an opportunity to receive the Corresponding
		Source of your version by providing access to the Corresponding Source
		from a network server at no charge, through some standard or customary
		means of facilitating copying of software.  This Corresponding Source
		shall include the Corresponding Source for any work covered by version 3
		of the GNU General Public License that is incorporated pursuant to the
		following paragraph.

		  Notwithstanding any other provision of this License, you have
		permission to link or combine any covered work with a work licensed
		under version 3 of the GNU General Public License into a single
		combined work, and to convey the resulting work.  The terms of this
		License will continue to apply to the part which is the covered work,
		but the work with which it is combined will remain governed by version
		3 of the GNU General Public License.

		  14. Revised Versions of this License.

		  The Free Software Foundation may publish revised and/or new versions of
		the GNU Affero General Public License from time to time.  Such new versions
		will be similar in spirit to the present version, but may differ in detail to
		address new problems or concerns.

		  Each version is given a distinguishing version number.  If the
		Program specifies that a certain numbered version of the GNU Affero General
		Public License "or any later version" applies to it, you have the
		option of following the terms and conditions either of that numbered
		version or of any later version published by the Free Software
		Foundation.  If the Program does not specify a version number of the
		GNU Affero General Public License, you may choose any version ever published
		by the Free Software Foundation.

		  If the Program specifies that a proxy can decide which future
		versions of the GNU Affero General Public License can be used, that proxy's
		public statement of acceptance of a version permanently authorizes you
		to choose that version for the Program.

		  Later license versions may give you additional or different
		permissions.  However, no additional obligations are imposed on any
		author or copyright holder as a result of your choosing to follow a
		later version.

		  15. Disclaimer of Warranty.

		  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
		APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
		HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
		OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
		THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
		PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
		IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
		ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

		  16. Limitation of Liability.

		  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
		WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
		THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
		GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
		USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
		DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
		PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
		EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
		SUCH DAMAGES.

		  17. Interpretation of Sections 15 and 16.

		  If the disclaimer of warranty and limitation of liability provided
		above cannot be given local legal effect according to their terms,
		reviewing courts shall apply local law that most closely approximates
		an absolute waiver of all civil liability in connection with the
		Program, unless a warranty or assumption of liability accompanies a
		copy of the Program in return for a fee.

		                     END OF TERMS AND CONDITIONS

		            How to Apply These Terms to Your New Programs

		  If you develop a new program, and you want it to be of the greatest
		possible use to the public, the best way to achieve this is to make it
		free software which everyone can redistribute and change under these terms.

		  To do so, attach the following notices to the program.  It is safest
		to attach them to the start of each source file to most effectively
		state the exclusion of warranty; and each file should have at least
		the "copyright" line and a pointer to where the full notice is found.

		    <one line to give the program's name and a brief idea of what it does.>
		    Copyright (C) <year>  <name of author>

		    This program is free software: you can redistribute it and/or modify
		    it under the terms of the GNU Affero General Public License as published
		    by the Free Software Foundation, either version 3 of the License, or
		    (at your option) any later version.

		    This program is distributed in the hope that it will be useful,
		    but WITHOUT ANY WARRANTY; without even the implied warranty of
		    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		    GNU Affero General Public License for more details.

		    You should have received a copy of the GNU Affero General Public License
		    along with this program.  If not, see <https://www.gnu.org/licenses/>.

		"""

	// --- Community & legal docs ---
	"CODE_OF_CONDUCT.md": """
		# 📜 Code of Conduct | .rice OS Protocol

		Version: 1.0.0-Stable

		Scope: Universal Runtime Environment

		## 0. The Root Philosophy 🧠

		.rice is about Maximum Performance and Zero Friction. We are here to merge the world's most powerful low-level and high-level logic into a single near-metal masterpiece.

		In this ecosystem, human interaction is treated like system-bus communication: it must be High-Bandwidth, Low-Latency, and Type-Safe. If your behavior causes social-bloat or community-instability, you will be rm -rf-ed from the kingdom.

		## 1. The Stack Ethics (Guild Standards) ⚡

		Every contributor must embody the spirit of the roles they serve. Respect the technology, respect the dev:

		    SMITH Resilience (Go/Elixir): Be the healer. If you see a junior's "logic-error," don't just point it out—provide the patch. Empathy is our failover mechanism.

		    CLERK Precision (Rust/Zig/Haskell): Logic > Ego. Attacks on code are welcome (keep it optimized!). Attacks on humans are unhandled exceptions. Be mathematically precise in your feedback.

		    SAGE Intelligence (Python/Mojo): Be a mentor. Share your wisdom. We don't gatekeep knowledge; we distribute it to optimize the collective mind.

		    BARD Expression (Ruby/TS/Flutter): Maintain the Vibe. Communication should be as clean and elegant as our UI. No messy drama, just high-fidelity interaction.

		    MASON Integrity (CUE): Respect the boundaries. Follow the King's conventions. Consistency in the community is as vital as consistency in the infrastructure.

		## 2. Unacceptable Behavior (exit 1) 🚫

		The following actions are considered Critical Vulnerabilities and will trigger an immediate system-override:

		    Trolling & Harassment: Any attempt to inject mental-bloat or emotional-noise into the workspace.

		    Data Leakage (Doxing): Sharing private data is a zero-day exploit. Instant and permanent de-authentication from the ecosystem.

		    Discriminatory Logic: We don't care about your hardware specs, only your output. Discrimination based on identity is a core-corruption that will be purged.

		    Spam & Latency: Keep it tech-focused. Off-topic garbage is considered a DDoS attack on our collective productivity.

		## 3. Enforcement Logic 🛠️

		The KING (Maintainers) will act as the kernel-level process for dispute resolution. We follow a linear escalation path:

		    WARN (Log.Info): A private notification to refactor your behavior and fix your logic-error.

		    REFRESH (SIGSTOP): A temporary suspension to cool down your CPU and prevent system-wide heat.

		    PURGE (SIGKILL): Permanent removal from the .rice organization, repos, and communication channels.

		Report Vulnerabilities to: infocoderice@gmail.com

		(Priority: High | Encryption: Required)

		## 4. Attribution & Integrity 📜

		This protocol is optimized from the Contributor Covenant and Mozilla's Ladder, then stripped of all non-essential bloat to fit the .rice architecture.

		    Final Instruction: Work with the speed of FLOW, the wisdom of MIND, and the precision of SAFE. Let's cook the future.
		"""

	"CONTRIBUTING.md": """
		# Contributing to .rice (NOT READY)

		Welcome to the pit stop. If you want to push code to .rice, you need to follow
		the High-Performance Protocol. No bloat, no legacy, just pure logic.

		## The Toolbox (Zero-Config)

		We don't do manual installs. We use Pixi.

		## The Polyglot Manifesto (How we code)

		In .rice, we use the right tool for the job. Here’s the "logic-gate" for our 8 languages:

		- **Rust** – Core logic & safety. If it's critical, it's Rust. Use cargo fmt.

		- **Zig** – Hardcore memory management & low-level wizardry. No hidden
		  control flow.

		- **Mojo** – AI infrastructure. Performance of C, flexibility of Python.

		- **Go** – Networking & Cloud (Traefik/Gateway). Keep it simple, keep it fast.

		- **Ruby** – Live-coding audio & rapid prototyping. Imagination over syntax.

		- **TypeScript** – Frontend interfaces (Muse/Bard). Strict types only.

		- **Python** – Glue code & ML high-level scripts. Use it sparingly.

		- **CUE** – Configuration & Infrastructure. If it's a config, it must be
		  validated.

		## The "Near-Metal" Workflow

		- **Sync** – `git pull origin main` + `pixi update`.
		- **Branch** – `git checkout -b feat/your-innovation`.
		- **Hack** – Use Cursor with our .cursor/ rules. Let the AI help you optimize.
		- **Verify** – `just test` (triggers Dagger to test across all 8 languages).
		- **Commit** – We use Conventional Commits (e.g. feat(zig): optimize memory
		  allocator).

		## Building & Shipping

		Everything is orchestrated by Dagger. We don't care about "it works on my
		machine".

		## Standards (The .rice Way)

		- **Zero Bloat** – If you can do it without a new dependency, do it.
		- **Emotes in Code** – Use them in comments to explain the vibe of the logic.
		- **Documentation** – Update docs/ARCHITECTURE.md if you change the "wiring"
		  between languages.

		## Final Rule: Exit 0

		If the CI isn't green, the code is broken. No exceptions. We ship only
		Maximum Performance.

		Ready to race? Open a PR and let's build the future.
		"""

	"SECURITY.md": """
		# 🛡️ .rice Security Protocol: Zero Treason

		In the .rice ecosystem, security isn't just "bug-fixing." It is resistance against betrayal. Ads, telemetry, and hidden corporate backdoors are treated as high-severity vulnerabilities. We leverage the full open-source arsenal to keep the system locked down on 8-9 bolts.
		📋 Fortress Status
		Component Trust Level Defense Mechanism
		Core AIOS 🔒 Absolute AGPLv3 + Forced Static Analysis
		Interface (Muse/Bard) 🎨 Fluid Biome + Tailwind isolation + Ruby Near-Metal
		Connectivity (GEO) 🌐 Stealth Proxy-first + Zero-Trace Generative Engine
		Dependencies 🏗️ Hardened pixi.lock + Cargo-Audit + Trufflehog
		🚨 Reporting a Breach

		If you find a hole that would let a "Commissar" or a corporate bot peer into the system:

		    Do NOT report via public issues. We don't give free lessons to spies.

		    Encrypt your intel. Send the report to: infocoderice@gmail.com with the subject [BREACH].

		    The Brief: Detail the exploit, what "leaks," and how to seal the bolt.

		Response Timeline:

		    CRITICAL (Data Leak/Corporate Backdoor): We react before your coffee gets cold.

		    MEDIUM (Privacy/Logic Flaws): Maximum 48h.
		🛠️ The Arsenal (The 8-9 Bolts)

		We don't trust, we verify. Paranoia is automated via our pixi stack:

		1. Static Defense (The White-List)

		    Rust & Go: We enforce cargo-audit, clippy, and govulncheck. Code must be as clean as a diamond.

		    Python/Mojo: ruff and bandit ensure AI scripts don't become Trojan horses for the cloud giants.

		    Trufflehog: Every commit is scanned. If you leak an API key, the system rejects the pulse.

		2. Infrastructure Hardening

		    Trivy & Checkov: Sourcing only the cleanest containers. Our infrastructure is invisible to corporate scanners.

		    Sops & Age: Your secrets are encrypted at rest and in motion before they even hit git push.

		3. Smart Contract Integrity

		    Foundry & Anchor: If the code touches a network, it goes through a testing hell. Every contract is an armored vault.

		🔐 Rules of Engagement (Best Practices)
		For Contributors

		    Zero Telemetry: If your code tries to "phone home" to Google, AWS, or Azure, it will be nuked.

		    Local-First AI: Logic belongs on the user’s device (RAM), not in a corporate cloud.

		    Lefthook: Our pre-commit hooks are the first line of defense. They won't let lazy or "leaky" code through.

		For Users

		    No Root, No Spy: .rice is your property. We don't grant permissions to 3rd party "vulture" apps.

		    GEO Privacy: Use Generative Engine Optimization to mask your intent behind our local algorithm.
		📢 Privacy Manifesto

		    "Advertising in a phone is treason. Listening to a user is a crime. An Operating System must be your servant, not a spy for your enemy."

		We follow Coordinated Vulnerability Disclosure. We credit those who help us and destroy exploits before Google can clone them.

		Last Updated: 2026-02-18 (Era of Liberated AI)

		Thank you for guarding the gates of .rice. Your vigilance is our freedom. 🙏
		"""

	// --- Repo readme (The Great Guilds — source of truth in CUE) ---
	"README.md": """
		# 🍚 .rice | The Sovereign Architecture

		*Total Privacy. Absolute Performance. The World is Our Grain.*

		## 🏛️ The Great Guilds | System Roles

		### 🫅 KING — The Root Protocol

		The King is the hard-coded authority of the repository. He doesn't execute applications; he enforces constraints. He is the single source of truth for global configurations, security compliance, and system-wide conventions.

		    >The "Why": To prevent configuration drift and data-leakage. The King ensures the entire stack remains a unified, anti-entropic environment where privacy is enforced at the root.

		    >The "What": Governs the root directory, managing the core blueprints and the high-level governance files that dictate how the machine behaves.

		### 👷 MASON — The Infrastructure Architect

		The Mason engineers the deployment pipelines and structural prototypes. He defines the immutable foundations that allow the system to scale without breaking.

		    >The "Why": A high-performance OS requires rigid structural integrity. The Mason ensures that the infrastructure is containerized, reproducible, and deep-linked to the hardware.

		    >The "What": Builds the CI/CD pipelines, the cloud-native schematics, and the low-level foundations required to reach "near-metal" speeds.

		### 🧑‍🏭 SMITH — The Resilience Engine

		The Smith is the guardian of the self-healing microservice mesh. He forges the high-speed communication layers and real-time recovery systems that keep the stack alive under any load.

		    >The "Why": In a world of 24/7 uptime, failure is not an option. The Smith creates the fault-tolerant messengers that allow services to communicate with zero latency and auto-repair on-the-fly.

		    >The "What": Generates the automated resources the King requires and ensures the system remains immortal through redundant, lightning-fast logic.

		### 👨‍💼 CLERK — The Computational Auditor

		The Clerk manages the high-precision logic and financial compliance. He is the verification engine that ensures every calculation is mathematically perfect and every transaction is cryptographically secure.

		    >The "Why": Precision is the ultimate currency. The Clerk handles zero-knowledge proofs and complex algorithmic flows, ensuring the system is 101% compliant with global financial and data standards.

		    >The "What": Oversees the automated ledger, verifying data integrity and managing the secure exchange of value across the blockchain or local memory.

		### 🧑‍🎤 BARD — The Experience Layer (UX/FX)

		The Bard is the high-fidelity sensory output of the system. He translates raw data and logic into immersive interfaces, generative audio, and fluid visual experiences.

		    >The "Why": Technology is useless if it's not intuitive. The Bard uses AI-driven design to create interfaces that breathe and respond, turning the terminal into a cinematic masterpiece.

		    >The "What": Handles the front-end expression—the GL-accelerated graphics, the voice synthesis, and the entire human-machine interface (HMI).

		### 🧑‍🔬 SAGE — The Cognitive Processor

		The Sage is the AI-orchestrator and data-science powerhouse. He processes massive data streams to find hidden patterns and provides the heuristic intelligence that drives the King's decisions.

		    >The "Why": To achieve AGI-level efficiency. The Sage runs real-time simulations and predictive modeling, allowing the OS to "see" network threats or user needs before they manifest.

		    >The "What": The primary source of all neural processing, quantum-grade simulations, and advanced research within the stack.

		### 👨‍🍳 CHIEF — The Stack Orchestrator

		The Master of the Feast.
		You are the Chief. You don't get bogged down in individual languages or low-level debugging. You speak .rice—the native high-level syntax of the system. You are the one who composes the precision of the Clerk, the aesthetics of the Bard, and the power of the Smith into a single, high-performance product.

		    >The Mission: To orchestrate the raw, near-metal output of every guild into a unified digital weapon that outperforms legacy systems._

		    >The Result: A system that is yours by design, runs at the speed of thought, and treats your data as a sacred, encrypted asset.
		"""

	// Renovate: automated dependency updates (schedule, rules, labels).
	"renovate.json": """
		{"$schema":"https://docs.renovatebot.com/renovate-schema.json","description":"Renovate configuration for Rice Monorepo - Automated dependency updates","extends":["config:base",":dependencyDashboard",":semanticCommits",":preserveSemverRanges","group:monorepos","group:recommended","replacements:all","workarounds:all"],"timezone":"UTC","schedule":["before 6am on Monday"],"prConcurrentLimit":10,"prHourlyLimit":5,"rebaseWhen":"conflicted","automerge":false,"platformAutomerge":false,"rangeStrategy":"bump","semanticCommits":"enabled","commitMessagePrefix":"chore(deps):","commitMessageAction":"update","commitMessageTopic":"{{depName}}","commitMessageExtra":"to {{#if isPinDigest}}{{{newDigestShort}}}{{else}}{{#if isMajor}}{{prettyNewMajor}}{{else}}{{#if isSingleVersion}}{{prettyNewVersion}}{{else}}{{#if newValue}}{{{newValue}}}{{else}}{{{newDigestShort}}}{{/if}}{{/if}}{{/if}}{{/if}}","labels":["dependencies","renovate"],"assignees":["@mrDinkelman"],"reviewers":["@mrDinkelman"],"vulnerabilityAlerts":{"labels":["security","dependencies"],"automerge":false,"schedule":["at any time"]},"separateMajorMinor":true,"separateMultipleMajor":true,"separateMinorPatch":false,"ignoreUnstable":true,"respectLatest":true,"packageRules":[{"description":"Group all non-major updates together","matchUpdateTypes":["minor","patch","pin","digest"],"groupName":"all non-major dependencies","groupSlug":"all-minor-patch"},{"description":"Automerge non-major updates","matchUpdateTypes":["minor","patch","pin","digest"],"automerge":true,"automergeType":"pr","platformAutomerge":true},{"description":"Major updates require manual review","matchUpdateTypes":["major"],"automerge":false,"labels":["dependencies","major-update"]},{"description":"Bun - Frontend/JS packages","matchManagers":["bun"],"matchPaths":["**/package.json"],"groupName":"frontend dependencies","schedule":["before 6am on Monday"],"labels":["dependencies","frontend"]},{"description":"Python - Bot packages","matchManagers":["pip_requirements","pip_setup","pipenv","poetry"],"matchPaths":[".bot/*"],"groupName":"bots dependencies","labels":["dependencies","bots","python"]},{"description":"Go - Backend packages","matchManagers":["gomod"],"matchPaths":[".backend/*"],"groupName":"backend dependencies","labels":["dependencies","backend","go"]},{"description":"Rust - Smart contracts","matchManagers":["cargo"],"matchPaths":[".backend/contract/rust/*"],"groupName":"rust contract dependencies","labels":["dependencies","rust","smart-contracts"]},{"description":"Solidity - EVM contracts","matchManagers":["bun"],"matchPaths":[".backend/contract/solidity/*"],"groupName":"solidity dependencies","labels":["dependencies","solidity","smart-contracts"]},{"description":"Terraform - Infrastructure","matchManagers":["terraform"],"matchPaths":[".devcontainer/terraform/*"],"groupName":"terraform dependencies","labels":["dependencies","terraform","infrastructure"]},{"description":"Kubernetes - Container orchestration","matchManagers":["helm-values","helmv3","kubernetes"],"matchPaths":[".devcontainer/kubernetes/*"],"groupName":"kubernetes dependencies","labels":["dependencies","kubernetes"]},{"description":"Dart/Flutter - Mobile","matchManagers":["pub"],"matchPaths":[".project/*/desktop/**",".project/*/mobile/**"],"groupName":"dart/flutter dependencies","labels":["dependencies","dart","flutter"]},{"description":"DevOps tools - High priority","matchPackageNames":["docker","kubernetes","terraform","helm"],"priority":10},{"description":"Security packages - Immediate","matchPackagePatterns":["^security-","^@security/"],"schedule":["at any time"],"automerge":false,"labels":["security","dependencies"]},{"description":"TypeScript and related","matchPackageNames":["typescript","@types/node"],"groupName":"typescript","labels":["dependencies","typescript"]},{"description":"React ecosystem","matchPackagePatterns":["^react","^@types/react"],"groupName":"react","labels":["dependencies","react"]},{"description":"Testing packages","matchPackagePatterns":["jest","vitest","playwright","cypress","^@testing-library/"],"groupName":"testing","labels":["dependencies","testing"]},{"description":"Linting and formatting","matchPackagePatterns":["eslint","prettier","^@typescript-eslint/","^eslint-"],"groupName":"linting","labels":["dependencies","linting"]},{"description":"Pixi - root toolchain (pixi.toml)","matchManagers":["pixi"],"matchPaths":["pixi.toml"],"groupName":"pixi toolchain","labels":["dependencies","tool-versions","pixi"],"schedule":["before 6am on Monday"],"automerge":false,"commitMessagePrefix":"chore(tools):"},{"description":"Pin action digests","matchManagers":["github-actions"],"pinDigests":true},{"description":"GitHub Actions","matchManagers":["github-actions"],"groupName":"github-actions","labels":["dependencies","github-actions"],"schedule":["before 6am on Monday"]}],"regexManagers":[{"description":"Update _VERSION variables in Dockerfiles","fileMatch":["(^|/)Dockerfile$","(^|/)Dockerfile\\.[^/]*$"],"matchStrings":["# renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)( versioning=(?<versioning>.*?))?\\s(ARG|ENV) .*?_VERSION=(?<currentValue>.*)\\s"],"versioningTemplate":"{{#if versioning}}{{{versioning}}}{{else}}semver{{/if}}"}],"docker":{"enabled":true,"pinDigests":true,"major":{"enabled":true}},"hostRules":[],"prBodyColumns":["Package","Type","Update","Change","Pending"],"prBodyDefinitions":{"Age":"[![age](https://developer.mend.io/api/mc/badges/age/{{datasource}}/{{replace '/' '%2f' depName}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)","Adoption":"[![adoption](https://developer.mend.io/api/mc/badges/adoption/{{datasource}}/{{replace '/' '%2f' depName}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)","Passing":"[![passing](https://developer.mend.io/api/mc/badges/compatibility/{{datasource}}/{{replace '/' '%2f' depName}}/{{currentVersion}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)","Confidence":"[![confidence](https://developer.mend.io/api/mc/badges/confidence/{{datasource}}/{{replace '/' '%2f' depName}}/{{currentVersion}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)"},"prBodyNotes":["This PR was generated by [Renovate](https://github.com/renovatebot/renovate).","🔒 To stop Renovate from automatically updating this dependency, add it to the `ignoreDeps` array of your `renovate.json`."]}
		"""

	// VS Code / Cursor multi-root workspace: folders (custom, bot, frontend, …), settings, extensions.
	// Zapis wieloliniowy – wygenerowany rice.code-workspace będzie czytelny (nie jedna długa linia).
	"rice.code-workspace": """
		{
		  "folders": [
		    {"name": "👨‍🍳CHIEF", "path": "custom"},
		    {"name": "🧑‍🔬SAGE", "path": "bot"},
		    {"name": "🧑‍🎤BARD", "path": "frontend"},
		    {"name": "👨‍💼CLERK", "path": "store"},
		    {"name": "🧑‍🏭SMITH", "path": "service"},
		    {"name": "👷MASON", "path": "infra"},
		    {"name": "🫅KING", "path": "."}
		  ],
		  "settings": {
		    "workbench.colorTheme": "Tokyo Night",
		    "workbench.iconTheme": "material-icon-theme",
		    "material-icon-theme.activeIconPack": "react_redux",
		    "material-icon-theme.folders.theme": "specific",
		    "material-icon-theme.folders.associations": {"🍚": "folder-root", "📦": "folder-package"},
		    "material-icon-theme.saturation": 1,
		    "material-icon-theme.opacity": 1,
		    "vscode-pets.petSize": "medium",
		    "vscode-pets.theme": "winter",
		    "vscode-pets.throwBallWithMouse": true,
		    "editor.cursorSmoothCaretAnimation": "on",
		    "editor.cursorBlinking": "smooth",
		    "editor.smoothScrolling": true,
		    "editor.fontFamily": "'Fira Code', 'JetBrains Mono', monospace",
		    "editor.fontLigatures": true,
		    "editor.minimap.enabled": false,
		    "editor.scrollbar.vertical": "hidden",
		    "editor.renderLineHighlight": "all",
		    "editor.letterSpacing": 0.33,
		    "editor.lineHeight": 25,
		    "npm.enableScriptExplorer": false,
		    "git.openRepositoryInParentFolders": "always",
		    "explorer.confirmDragAndDrop": false,
		    "outline.showVariables": false,
		    "outline.showFields": false,
		    "scm.diffDecorations": "gutter",
		    "editor.linkedEditing": true,
		    "editor.formatOnSave": true,
		    "files.trimTrailingWhitespace": true,
		    "files.insertFinalNewline": true,
		    "editor.bracketPairColorization.enabled": true,
		    "editor.guides.bracketPairs": "active",
		    "errorLens.enabledDiagnosticLevels": ["error", "warning"],
		    "errorLens.fontStyleItalic": true,
		    "[python]": {"editor.defaultFormatter": "charliermarsh.ruff", "editor.codeActionsOnSave": {"source.organizeImports": "explicit"}},
		    "[typescript][javascript][json][jsonc]": {"editor.defaultFormatter": "biomejs.biome"},
		    "[rust]": {"editor.defaultFormatter": "rust-lang.rust-analyzer"},
		    "[terraform]": {"editor.formatOnSave": false},
		    "[ruby]": {"editor.defaultFormatter": "shopify.ruby-lsp", "editor.formatOnSave": true},
		    "[glsl]": {"editor.defaultFormatter": "slevesque.vscode-glsl"},
		    "todo-tree.highlights.defaultHighlight": {"type": "text", "fontWeight": "bold", "borderRadius": "4px"},
		    "files.associations": {"Justfile": "just", "*.mojo": "mojo", "*.bacon": "toml", ".envrc": "shellscript", "*.cue": "cue", "*.tf.json": "json", "*.frag": "glsl", "*.vert": "glsl", "*.glsl": "glsl", "*.rb": "ruby"},
		    "emeraldwalk.runonsave": {"commands": [{"match": "infra/config/.*[.]cue$", "cmd": "cd \"${workspaceFolder}\" && cue cmd gen ./infra"}]}
		  },
		  "tasks": {
		    "version": "2.0.0",
		    "tasks": [{"label": "King: generate root from CUE", "type": "shell", "command": "cue cmd gen ./infra", "options": {"cwd": "${workspaceFolder:🫅KING}"}, "group": "build", "presentation": {"reveal": "silent", "panel": "shared"}}]
		  },
		  "extensions": {
		    "recommendations": [
		      "emeraldwalk.runonsave", "enkia.tokyo-night", "pkief.material-icon-theme", "usernamehw.errorlens",
		      "tonybaloney.vscode-pets", "oderwat.indent-rainbow", "aaron-bond.better-comments", "gruntfuggly.todo-tree",
		      "rust-lang.rust-analyzer", "ziglang.vscode-zig", "modular-mojotools.mojo", "charliermarsh.ruff",
		      "biomejs.biome", "cuelangorg.vscode-cue", "golang.go", "elixir-lsp.elixir-ls", "haskell.haskell",
		      "dart-code.flutter", "rebornix.ruby", "shopify.ruby-lsp", "slevesque.vscode-glsl", "circledev.glsl-canvas",
		      "iden3.circom", "mkhl.direnv", "skellock.just", "signageos.signageos-vscode-sops", "tamasfe.even-better-toml",
		      "hashicorp.terraform", "redhat.vscode-yaml", "zxh404.vscode-proto3", "bierner.markdown-mermaid",
		      "antfu.browse-lite", "aquasecurity.trivy-vulnerability-scanner", "github.vscode-github-actions"
		    ]
		  }
		}
		"""

	// --- Taplo: TOML formatting ---
	"taplo.toml": """
		include = ["**/*.toml"]
		exclude = ["target/**", "node_modules/**", ".venv/**", "venv/**", "dist/**", "build/**"]
		[formatting]
		align_entries = true
		align_comments = true
		array_trailing_comma = true
		column_width = 120
		trailing_newline = true
		crlf = false
		[schema]
		enabled = true
		"""

	"vhs.tape": ""

	// --- Secrets (SOPS), Docker, Markdown, Terraform lint, Atlas, Compose ---
	".sops.yaml": """
		creation_rules:
		  - path_regex: \\.secrets.*\\.yaml$
		    age: >-
		      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		"""

	".dockerignore": """
		.git
		.gitignore
		.gitattributes
		.github
		.vscode
		.idea
		*.swp
		*.swo
		*~
		**/node_modules
		**/dist
		**/build
		**/target
		**/__pycache__
		**/*.pyc
		**/.pytest_cache
		**/.mypy_cache
		**/.ruff_cache
		**/bazel-*
		**/.next
		**/.nuxt
		**/*.log
		**/logs
		.DS_Store
		Thumbs.db
		**/*.md
		!README.md
		**/*test*
		**/*spec*
		**/.cache
		**/.npm
		**/.yarn
		**/.pnpm-store
		**/.cargo/registry
		**/.cargo/git
		**/.gradle
		**/.m2
		@generated
		generated
		**/.venv
		**/venv
		**/env
		**/tmp
		**/temp
		**/*.tmp
		"""

	// Markdown lint rules (markdownlint-cli2).
	".markdownlint.json": """
		{"$schema":"https://raw.githubusercontent.com/DavidAnson/markdownlint/main/schema/markdownlint-config-schema.json","default":true,"MD001":true,"MD003":{"style":"atx"},"MD004":{"style":"dash"},"MD007":{"indent":2},"MD013":{"line_length":120,"heading_line_length":120,"code_block_line_length":150,"code_blocks":false,"tables":false,"headings":false,"strict":false,"stern":false},"MD024":{"siblings_only":true},"MD025":{"front_matter_title":"^\\\\s*title\\\\s*[:=]"},"MD026":{"punctuation":".,;:!"},"MD029":{"style":"ordered"},"MD033":{"allowed_elements":["details","summary","br","img","a","table","thead","tbody","tr","th","td","div","span","sup","sub","kbd","code","pre","picture","source"]},"MD034":false,"MD036":false,"MD040":true,"MD041":false,"MD046":{"style":"fenced"},"MD049":{"style":"underscore"},"MD050":{"style":"asterisk"},"MD051":false,"no-hard-tabs":true,"whitespace":true,"no-duplicate-heading":false,"no-multiple-blanks":{"maximum":2}}
		"""

	// TFLint: Terraform lint plugin and rules.
	".tflint.hcl": """
		config {
		  module = true
		  force = false
		  disabled_by_default = false
		}
		plugin "terraform" {
		  enabled = true
		  preset  = "recommended"
		}
		rule "terraform_deprecated_interpolation" { enabled = true }
		rule "terraform_deprecated_index" { enabled = true }
		rule "terraform_unused_declarations" { enabled = true }
		rule "terraform_comment_syntax" { enabled = true }
		rule "terraform_documented_outputs" { enabled = false }
		rule "terraform_documented_variables" { enabled = false }
		rule "terraform_typed_variables" { enabled = true }
		rule "terraform_module_pinned_source" { enabled = true }
		rule "terraform_naming_convention" { enabled = true }
		rule "terraform_required_version" { enabled = true }
		rule "terraform_required_providers" { enabled = true }
		rule "terraform_standard_module_structure" { enabled = true }
		rule "terraform_workspace_remote" { enabled = true }
		"""

	"atlas.hcl": ""

	// Root compose: includes stack + optional project profiles.
	"docker-compose.yml": """
		name: ${DOCKER_COMPOSE_PROJECT_NAME:-devcontainer}

		# ==============================================================================
		# Main Docker Compose Entry Point
		# ==============================================================================
		# This file serves as the unified entry point for all Docker Compose services.
		# It includes infrastructure services and all project-specific services.
		#
		# Usage:
		#   docker compose up                    # Start all services
		#   docker compose up --profile ceramix  # Start specific project profile
		#   docker compose up --profile core     # Start only infrastructure services
		#
		# Environment Variables:
		#   Variables are loaded from .envrc (via direnv) - ensure direnv is loaded:
		#     direnv allow  # First time only
		#
		#   Key variables used (defined in .envrc):
		#     - DOCKER_COMPOSE_PROJECT_NAME: Project name (default: devcontainer)
		#     - DOCKER_NETWORK: Network name for all services (default: crice)
		#     - All service URLs, ports, and configuration from .envrc
		#
		#   Docker Compose automatically inherits environment variables from the shell
		#   when direnv is loaded. Alternatively, you can create a .env file manually.
		# ==============================================================================

		# Load environment variables from .env file (optional, if exists)
		# Primary source is .envrc via direnv - this is a fallback
		env_file:
		  - .env

		include:
		  # Stack services (required) - Backend, Bot, Contract, DevContainer
		  - path: .devcontainer/docker-compose.stack.yml
		    required: true

		  # Project-specific services (optional, loaded based on profiles)
		  # Each project has its own profile (e.g., --profile ceramix)
		  - path: .project/ceramix/docker-compose.ceramix.yml
		    required: false
		  - path: .project/medical/docker-compose.medical.yml
		    required: false
		  - path: .project/e-commerce/docker-compose.e-commerce.yml
		    required: false
		  - path: .project/meowtopia/docker-compose.meowtopia.yml
		    required: false
		  - path: .project/code-rice/docker-compose.code-rice.yml
		    required: false

		# Default network configuration
		# Uses DOCKER_NETWORK from .envrc (default: crice)
		# Network is created if it doesn't exist, or uses existing external network
		networks:
		  default:
		    name: ${DOCKER_NETWORK:-crice}
		    driver: bridge
		"""
}

// king_outputs usunięte – w CUE v0.15 for path in order { content: king_content[path] } daje invalid index.
// cue cmd gen eksportuje config.order i config.king_content i iteruje w skrypcie (manifest_tool.cue).
