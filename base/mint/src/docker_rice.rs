//! Parse CHIEF `docker.rice` → `infra/gen/chief/docker_project.cue` (schema: `infra/proto/cue/infra.cue`).

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct BotRole {
    pub model_id: String,
    pub backend: String,
    pub quantization: Option<String>,
    pub pull_on_start: Option<bool>,
}

#[derive(Debug, Clone)]
pub struct DockerRiceConfig {
    pub db_name: String,
    pub db_user: String,
    pub init_sql_extensions: Vec<String>,
    pub init_sql_extra: Vec<String>,
    pub memory: MemoryLimits,
    pub redis_maxmemory: Option<String>,
    pub qdrant: QdrantTuning,
    pub nats: NatsTuning,
    pub postal_profile: String,
    pub mailpit: MailpitConfig,
    pub ollama: Option<OllamaConfig>,
    pub vllm: Option<VllmConfig>,
    pub bot: BotTuning,
    pub server: crate::server_rice::ServerRiceConfig,
}

#[derive(Debug, Clone, Default)]
pub struct MemoryLimits {
    pub redis: String,
    pub yugabyte: String,
    pub qdrant: String,
    pub nats: String,
    pub temporal: String,
    pub ollama: Option<String>,
    pub vllm: Option<String>,
}

#[derive(Debug, Clone)]
pub struct QdrantTuning {
    pub hnsw_m: u32,
    pub ef_construct: u32,
    pub max_request_size_mb: u32,
    pub quantization: String,
}

#[derive(Debug, Clone)]
pub struct NatsTuning {
    pub jetstream_max_mem: String,
    pub jetstream_max_file: String,
    pub max_payload: String,
}

#[derive(Debug, Clone)]
pub struct MailpitConfig {
    pub profile: String,
    pub max_messages: String,
    pub database: String,
}

#[derive(Debug, Clone)]
pub struct OllamaConfig {
    pub profile: String,
    pub auto_pull: bool,
    pub max_models: u32,
    pub backend: String,
    pub memory_limit: String,
    pub keep_alive: String,
    pub num_parallel: String,
    pub gpu_count: u32,
    pub roles: HashMap<String, BotRole>,
}

#[derive(Debug, Clone)]
pub struct VllmConfig {
    pub profile: String,
    pub model: String,
    pub lora_mount: String,
    pub weights_mount: String,
    pub memory_limit: String,
    pub enable_lora: bool,
    pub max_lora_rank: String,
    pub gpu_memory_utilization: String,
    pub max_num_seqs: String,
    pub gpu_count: u32,
}

#[derive(Debug, Clone)]
pub struct BotTuning {
    pub pull_on_start_default: bool,
    pub pull_retries: u32,
    pub fallback_chain: Vec<String>,
}

impl Default for QdrantTuning {
    fn default() -> Self {
        Self {
            hnsw_m: 16,
            ef_construct: 100,
            max_request_size_mb: 32,
            quantization: "int8".into(),
        }
    }
}

impl Default for NatsTuning {
    fn default() -> Self {
        Self {
            jetstream_max_mem: "1GB".into(),
            jetstream_max_file: "10GB".into(),
            max_payload: "8MB".into(),
        }
    }
}

impl Default for BotTuning {
    fn default() -> Self {
        Self {
            pull_on_start_default: true,
            pull_retries: 3,
            fallback_chain: vec!["vllm".into(), "ollama".into()],
        }
    }
}

pub fn parse_docker_rice(src: &str) -> Result<DockerRiceConfig, String> {
    let body = crate::chief_rice_parse::extract_rc_let_body(src, "rc docker let")?;
    let blocks = crate::chief_rice_parse::parse_set_blocks(&body)?;

    let db = blocks.get("db").ok_or("missing required block: db set { ... }")?;
    let mem = blocks
        .get("memory")
        .ok_or("missing required block: memory set { ... }")?;
    let mailpit = blocks
        .get("mailpit")
        .ok_or("missing required block: mailpit set { ... }")?;

    let mut init_extensions = Vec::new();
    let mut init_extra = Vec::new();
    if let Some(raw) = db.get("init_sql") {
        for item in parse_tuple_items(raw)? {
            if is_raw_sql(&item) {
                init_extra.push(normalize_sql_line(&item));
            } else {
                init_extensions.push(item);
            }
        }
    }
    if let Some(raw) = db.get("init_extra") {
        for item in parse_tuple_items(raw)? {
            init_extra.push(normalize_sql_line(&item));
        }
    }

    let memory = MemoryLimits {
        redis: require_field(mem, "redis")?,
        yugabyte: require_field(mem, "yugabyte")?,
        qdrant: require_field(mem, "qdrant")?,
        nats: require_field(mem, "nats")?,
        temporal: require_field(mem, "temporal")?,
        ollama: mem.get("ollama").map(|s| normalize_memory(s)),
        vllm: mem.get("vllm").map(|s| normalize_memory(s)),
    };

    let redis_maxmemory = blocks
        .get("redis")
        .and_then(|m| m.get("maxmemory"))
        .map(|s| normalize_memory(s))
        .or_else(|| Some(memory_limit_to_maxmemory(&memory.redis)));

    let qdrant = if let Some(q) = blocks.get("qdrant") {
        QdrantTuning {
            hnsw_m: parse_u32_field(q, "hnsw_m", 16)?,
            ef_construct: parse_u32_field(q, "ef_construct", 100)?,
            max_request_size_mb: parse_u32_field(q, "max_request_size_mb", 32)?,
            quantization: optional_field(q, "quantization", "int8"),
        }
    } else {
        QdrantTuning::default()
    };

    let nats = if let Some(n) = blocks.get("nats") {
        NatsTuning {
            jetstream_max_mem: optional_field(n, "jetstream_max_mem", "1GB"),
            jetstream_max_file: optional_field(n, "jetstream_max_file", "10GB"),
            max_payload: optional_field(n, "max_payload", "8MB"),
        }
    } else {
        NatsTuning::default()
    };

    let postal_profile = blocks
        .get("postal")
        .map(|p| optional_field(p, "profile", "_disabled"))
        .unwrap_or_else(|| "_disabled".into());

    let bot = if let Some(b) = blocks.get("bot") {
        BotTuning {
            pull_on_start_default: parse_bool(&optional_field(
                b,
                "pull_on_start_default",
                "true",
            ))?,
            pull_retries: parse_u32_field(b, "pull_retries", 3)?,
            fallback_chain: b
                .get("fallback_chain")
                .map(|raw| parse_name_tuple(raw))
                .transpose()?
                .unwrap_or_else(|| vec!["vllm".into(), "ollama".into()]),
        }
    } else {
        BotTuning::default()
    };

    let ollama = if let Some(ol) = blocks.get("ollama") {
        let models_raw = ol
            .get("models")
            .ok_or("ollama set: missing models = (...)")?;
        Some(OllamaConfig {
            profile: require_field(ol, "profile")?,
            auto_pull: parse_bool(&optional_field(ol, "auto_pull", "true"))?,
            max_models: parse_u32_field(ol, "max_models", 1)?,
            backend: require_field(ol, "backend")?,
            memory_limit: memory
                .ollama
                .clone()
                .ok_or("memory set: missing ollama when ollama set present")?,
            keep_alive: optional_field(ol, "keep_alive", "-1"),
            num_parallel: optional_field(ol, "num_parallel", "1"),
            gpu_count: parse_u32_field(ol, "gpu_count", 1)?,
            roles: parse_roles_tuple(models_raw)?,
        })
    } else {
        None
    };

    let vllm = if let Some(vl) = blocks.get("vllm") {
        Some(VllmConfig {
            profile: require_field(vl, "profile")?,
            model: require_field(vl, "model")?,
            lora_mount: require_field(vl, "lora.mount")?,
            weights_mount: require_field(vl, "weights.mount")?,
            memory_limit: memory
                .vllm
                .clone()
                .ok_or("memory set: missing vllm when vllm set present")?,
            enable_lora: parse_bool(&optional_field(vl, "enable_lora", "true"))?,
            max_lora_rank: optional_field(vl, "max_lora_rank", "128"),
            gpu_memory_utilization: optional_field(vl, "gpu_memory_utilization", "0.90"),
            max_num_seqs: optional_field(vl, "max_num_seqs", "1"),
            gpu_count: parse_u32_field(vl, "gpu_count", 1)?,
        })
    } else {
        None
    };

    let server = crate::server_rice::parse_server_from_blocks(&blocks)?;

    Ok(DockerRiceConfig {
        db_name: require_field(db, "name")?,
        db_user: require_field(db, "user")?,
        init_sql_extensions: init_extensions,
        init_sql_extra: init_extra,
        memory,
        redis_maxmemory,
        qdrant,
        nats,
        postal_profile,
        mailpit: MailpitConfig {
            profile: require_field(mailpit, "profile")?,
            max_messages: require_field(mailpit, "max_messages")?,
            database: require_field(mailpit, "database.mount")?,
        },
        ollama,
        vllm,
        bot,
        server,
    })
}

pub fn validate_docker_rice_profile(slug: &str, cfg: &DockerRiceConfig) -> Vec<String> {
    let mut errs = Vec::new();
    if slug == "egos.app" && cfg.ollama.is_none() {
        errs.push("egos.app requires ollama set { ... }".into());
    }
    if slug == "code-rice.com" && cfg.vllm.is_none() {
        errs.push("code-rice.com requires vllm set { ... }".into());
    }
    if let Some(v) = &cfg.vllm {
        if v.model.starts_with("env.") {
            errs.push("vllm model must be a literal, not env.*".into());
        }
    }
    errs.extend(crate::server_rice::validate_server_rice_profile(slug, &cfg.server));
    errs
}

pub fn extensions_to_init_sql(extensions: &[String]) -> Vec<String> {
    extensions
        .iter()
        .map(|ext| {
            let quoted = if ext.contains('-') {
                format!("\"{ext}\"")
            } else {
                ext.clone()
            };
            format!("CREATE EXTENSION IF NOT EXISTS {quoted};")
        })
        .collect()
}

pub fn memory_limit_to_maxmemory(limit: &str) -> String {
    let s = limit.trim();
    if s.is_empty() {
        return "512mb".into();
    }
    let upper = s.to_uppercase();
    if upper.ends_with("MB") {
        s.to_lowercase()
    } else if upper.ends_with('M') {
        format!("{}mb", &s[..s.len() - 1].to_lowercase())
    } else if upper.ends_with('G') && !upper.ends_with("GB") {
        format!("{}gb", &s[..s.len() - 1].to_lowercase())
    } else {
        s.to_lowercase()
    }
}

/// Render `infra/gen/chief/docker_project.cue` (merged via `params` in `infra/docker/cue/pack.cue`).
pub fn render_project_cue(project_name: &str, cfg: &DockerRiceConfig) -> String {
    let mut init_sql: Vec<String> = extensions_to_init_sql(&cfg.init_sql_extensions);
    init_sql.extend(cfg.init_sql_extra.clone());
    let init_sql_body = render_string_list(&init_sql);

    let redis_max = cfg
        .redis_maxmemory
        .clone()
        .unwrap_or_else(|| memory_limit_to_maxmemory(&cfg.memory.redis));

    let roles_cue = render_roles_cue(&cfg.ollama);
    let fallback_chain = render_string_list(&cfg.bot.fallback_chain);

    let stack_block = format!(
        r#"
}}

dockerStack: {{
	ollama:  {{ enabled: {ollama} }}
	vllm:    {{ enabled: {vllm} }}
	postal:  {{ enabled: {postal} }}
	mailpit: {{ enabled: true }}
}}"#,
        ollama = cfg.ollama.is_some(),
        vllm = cfg.vllm.is_some(),
        postal = cfg.postal_profile != "_disabled",
    );

    let ollama_block = if let Some(o) = &cfg.ollama {
        format!(
            r#"
		ollama: {{
			profile:          {profile}
			memoryLimit:      {mem}
			autoPull:         {auto_pull}
			backend:          {backend}
			maxLoadedModels:  "{max_models}"
			keepAlive:        {keep_alive}
			numParallel:      {num_parallel}
			gpuCount:         {gpu_count}
		}}"#,
            profile = cue_quote(&o.profile),
            mem = cue_quote(&o.memory_limit),
            auto_pull = o.auto_pull,
            max_models = o.max_models,
            backend = cue_quote(&o.backend),
            keep_alive = cue_quote(&o.keep_alive),
            num_parallel = cue_quote(&o.num_parallel),
            gpu_count = o.gpu_count,
        )
    } else {
        r#"
		ollama: {
			profile:          "_disabled"
			memoryLimit:      "0"
			autoPull:         false
			backend:          "ollama"
			maxLoadedModels:  "0"
			keepAlive:        "-1"
			numParallel:      "1"
			gpuCount:         0
		}"#
        .to_string()
    };

    let vllm_block = if let Some(v) = &cfg.vllm {
        format!(
            r#"
		vllm: {{
			profile:              {profile}
			memoryLimit:          {mem}
			model:                {model}
			loraMount:            {lora}
			weightsMount:         {weights}
			enableLora:           {enable_lora}
			maxLoraRank:          {max_lora_rank}
			gpuMemoryUtilization: {gpu_util}
			maxNumSeqs:           {max_seqs}
			gpuCount:             {gpu_count}
		}}"#,
            profile = cue_quote(&v.profile),
            mem = cue_quote(&v.memory_limit),
            model = cue_quote(&v.model),
            lora = cue_quote(&v.lora_mount),
            weights = cue_quote(&v.weights_mount),
            enable_lora = v.enable_lora,
            max_lora_rank = cue_quote(&v.max_lora_rank),
            gpu_util = cue_quote(&v.gpu_memory_utilization),
            max_seqs = cue_quote(&v.max_num_seqs),
            gpu_count = v.gpu_count,
        )
    } else {
        r#"
		vllm: {
			profile:              "_disabled"
			memoryLimit:          "0"
			model:                ""
			loraMount:            "../models/lora:/lora:ro"
			weightsMount:         "../models/weights:/weights:ro"
			enableLora:           false
			maxLoraRank:          "128"
			gpuMemoryUtilization: "0.90"
			maxNumSeqs:           "1"
			gpuCount:             0
		}"#
        .to_string()
    };

    format!(
        r#"package docker

// Generated — mint_overlay_check --apply-docker (CHIEF_PROJECT)
// Edit custom/*/bowl + custom/*/infra/docker.rice. Schema: infra/proto/cue/infra.cue

projectParams: #DockerParams & {{
	compose: {{
		projectName: {project}

		db: {{
			name: {db_name}
			user: {db_user}
		}}

		redis: {{
			memoryLimit: {mem_redis}
			maxmemory:   {redis_max}
		}}

		yugabyte: {{memoryLimit: {mem_yb}}}

		qdrant: {{
			memoryLimit:       {mem_qdrant}
			hnswM:             {q_hnsw}
			efConstruct:       {q_ef}
			maxRequestSizeMb:  {q_req}
			quantization:      {q_quant}
		}}

		nats: {{
			memoryLimit:      {mem_nats}
			jetstreamMaxMem:  {n_mem}
			jetstreamMaxFile: {n_file}
			maxPayload:       {n_payload}
		}}

		temporal: {{memoryLimit: {mem_temporal}}}

		postal: {{profile: {postal_profile}}}

		mailpit: {{
			profile:     {mailpit_profile}
			maxMessages: {mailpit_max}
			database:    {mailpit_db}
		}}{ollama_block}{vllm_block}
	}}

	db: {{
		init: {{
			sql: {init_sql}
		}}
	}}

	bot: {{
		registry: {{
			version:               "1"
			pull_on_start_default: {pull_default}
			pull_retries:          {pull_retries}
			roles:                 {roles}
			fallback_chain:        {fallback_chain}
		}}
	}}{stack_block}
"#,
        project = cue_quote(project_name),
        db_name = cue_quote(&cfg.db_name),
        db_user = cue_quote(&cfg.db_user),
        mem_redis = cue_quote(&cfg.memory.redis),
        redis_max = cue_quote(&redis_max),
        mem_yb = cue_quote(&cfg.memory.yugabyte),
        mem_qdrant = cue_quote(&cfg.memory.qdrant),
        q_hnsw = cfg.qdrant.hnsw_m,
        q_ef = cfg.qdrant.ef_construct,
        q_req = cfg.qdrant.max_request_size_mb,
        q_quant = cue_quote(&cfg.qdrant.quantization),
        mem_nats = cue_quote(&cfg.memory.nats),
        n_mem = cue_quote(&cfg.nats.jetstream_max_mem),
        n_file = cue_quote(&cfg.nats.jetstream_max_file),
        n_payload = cue_quote(&cfg.nats.max_payload),
        mem_temporal = cue_quote(&cfg.memory.temporal),
        postal_profile = cue_quote(&cfg.postal_profile),
        mailpit_profile = cue_quote(&cfg.mailpit.profile),
        mailpit_max = cue_quote(&cfg.mailpit.max_messages),
        mailpit_db = cue_quote(&cfg.mailpit.database),
        init_sql = init_sql_body,
        pull_default = cfg.bot.pull_on_start_default,
        pull_retries = cfg.bot.pull_retries,
        roles = roles_cue,
        fallback_chain = fallback_chain,
        ollama_block = ollama_block,
        vllm_block = vllm_block,
        stack_block = stack_block,
    )
}

fn render_roles_cue(ollama: &Option<OllamaConfig>) -> String {
    let Some(o) = ollama else {
        return "{}".to_string();
    };
    if o.roles.is_empty() {
        return "{}".to_string();
    }
    let mut keys: Vec<_> = o.roles.keys().collect();
    keys.sort();
    let mut lines = vec!["{".to_string()];
    for role in keys {
        let r = &o.roles[role.as_str()];
        let mut fields = vec![format!("\t\t\t\tmodel_id: {}", cue_quote(&r.model_id))];
        fields.push(format!(
            "\t\t\t\tbackend:  {}",
            cue_quote(r.backend.as_str())
        ));
        if let Some(q) = &r.quantization {
            fields.push(format!("\t\t\t\tquantization: {}", cue_quote(q)));
        }
        if let Some(p) = r.pull_on_start {
            fields.push(format!("\t\t\t\tpull_on_start: {}", p));
        }
        lines.push(format!("\t\t\t{}: {{\n{}\n\t\t\t}}", role, fields.join("\n")));
    }
    lines.push("\t\t}".to_string());
    lines.join("\n")
}

fn render_string_list(items: &[String]) -> String {
    if items.is_empty() {
        return "[]".to_string();
    }
    let items: Vec<String> = items.iter().map(|l| cue_quote(l)).collect();
    format!("[\n\t\t\t{},\n\t\t]", items.join(",\n\t\t\t"))
}

fn cue_quote(s: &str) -> String {
    format!("{:?}", s)
}

fn is_raw_sql(s: &str) -> bool {
    let u = s.to_uppercase();
    u.starts_with("CREATE ")
        || u.starts_with("INSERT ")
        || u.starts_with("ALTER ")
        || u.starts_with("--")
        || s.contains(';')
}

fn normalize_sql_line(s: &str) -> String {
    let s = s.trim();
    if s.ends_with(';') {
        s.to_string()
    } else {
        format!("{s};")
    }
}

fn parse_roles_tuple(raw: &str) -> Result<HashMap<String, BotRole>, String> {
    let inner = raw
        .trim()
        .strip_prefix('(')
        .and_then(|s| s.strip_suffix(')'))
        .ok_or("models must be a tuple: ( role.field = value, ... )")?;
    let mut roles: HashMap<String, BotRole> = HashMap::new();
    for part in split_top_level_commas(inner) {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let Some(eq) = part.find('=') else {
            return Err(format!("expected role.field = value in models: {part:?}"));
        };
        let key = part[..eq].trim();
        let val = normalize_atom(part[eq + 1..].trim());
        let Some((role, field)) = key.split_once('.') else {
            return Err(format!("models entry must use role.field = ..., got {key:?}"));
        };
        let entry = roles.entry(role.to_string()).or_insert_with(|| BotRole {
            model_id: String::new(),
            backend: "ollama".into(),
            quantization: None,
            pull_on_start: None,
        });
        match field {
            "model_id" => entry.model_id = val,
            "quantization" => entry.quantization = Some(val),
            "pull_on_start" => entry.pull_on_start = Some(parse_bool(&val)?),
            "backend" => entry.backend = val,
            _ => return Err(format!("unknown models field `{field}` on role `{role}`")),
        }
    }
    for (role, r) in &roles {
        if r.model_id.is_empty() {
            return Err(format!("role `{role}` missing model_id"));
        }
    }
    Ok(roles)
}

fn parse_name_tuple(raw: &str) -> Result<Vec<String>, String> {
    parse_tuple_items(raw)
}

fn parse_tuple_items(raw: &str) -> Result<Vec<String>, String> {
    let raw = raw.trim();
    let inner = raw
        .strip_prefix('(')
        .and_then(|s| s.strip_suffix(')'))
        .ok_or("expected tuple: (a, b, ...)")?;
    Ok(split_top_level_commas(inner)
        .into_iter()
        .map(|s| normalize_atom(&s))
        .filter(|s| !s.is_empty())
        .collect())
}

fn optional_field(map: &HashMap<String, String>, key: &str, default: &str) -> String {
    map.get(key)
        .map(|s| normalize_atom(s))
        .unwrap_or_else(|| default.to_string())
}

fn parse_u32_field(map: &HashMap<String, String>, key: &str, default: u32) -> Result<u32, String> {
    match map.get(key) {
        None => Ok(default),
        Some(v) => normalize_atom(v)
            .parse()
            .map_err(|_| format!("`{key}` must be a positive integer")),
    }
}

fn extract_let_body(src: &str) -> Result<String, String> {
    let mut in_let = false;
    let mut depth = 0i32;
    let mut body = String::new();
    for line in src.lines() {
        let t = line.trim();
        if t.is_empty() || t.starts_with("//") {
            continue;
        }
        if !in_let {
            if t.contains("rc docker let") {
                in_let = true;
                if let Some(pos) = line.find('{') {
                    depth = 1;
                    let rest = &line[pos + 1..];
                    if !rest.trim().is_empty() && !rest.trim().starts_with('}') {
                        body.push_str(rest);
                        body.push('\n');
                    }
                }
            }
            continue;
        }
        for ch in line.chars() {
            if ch == '{' {
                depth += 1;
                if depth > 1 {
                    body.push(ch);
                }
            } else if ch == '}' {
                depth -= 1;
                if depth == 0 {
                    return Ok(body);
                }
                body.push(ch);
            } else if depth >= 1 {
                body.push(ch);
            }
        }
        if depth >= 1 {
            body.push('\n');
        }
    }
    if in_let {
        Err("unclosed rc docker let { ... }".into())
    } else {
        Err("missing `rc docker let { ... }`".into())
    }
}

fn parse_set_blocks(body: &str) -> Result<HashMap<String, HashMap<String, String>>, String> {
    let mut blocks = HashMap::new();
    let chars: Vec<char> = body.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if i >= chars.len() {
            break;
        }
        let start = i;
        while i < chars.len() && (chars[i].is_alphanumeric() || chars[i] == '_') {
            i += 1;
        }
        let block_name: String = chars[start..i].iter().collect();
        if block_name.is_empty() {
            return Err(format!("expected block name at offset {start}"));
        }
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if !starts_with(&chars, i, "set") {
            return Err(format!("expected `set` after `{block_name}`"));
        }
        i += 3;
        while i < chars.len() && chars[i].is_whitespace() {
            i += 1;
        }
        if i >= chars.len() || chars[i] != '{' {
            return Err(format!("expected `{{` after `{block_name} set`"));
        }
        i += 1;
        let inner_start = i;
        let mut depth = 1i32;
        while i < chars.len() && depth > 0 {
            if chars[i] == '{' {
                depth += 1;
            } else if chars[i] == '}' {
                depth -= 1;
            }
            if depth > 0 {
                i += 1;
            }
        }
        let inner: String = chars[inner_start..i].iter().collect();
        i += 1;
        blocks.insert(block_name, parse_block_fields(&inner)?);
    }
    Ok(blocks)
}

fn parse_block_fields(inner: &str) -> Result<HashMap<String, String>, String> {
    let mut out = HashMap::new();
    for part in split_top_level_commas(inner) {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let Some(eq) = part.find('=') else {
            return Err(format!("expected `=` in assignment: {part:?}"));
        };
        let key = part[..eq].trim().to_string();
        let val = part[eq + 1..].trim().trim_end_matches(',').trim();
        if key.is_empty() {
            return Err("empty field name".into());
        }
        out.insert(key, val.to_string());
    }
    Ok(out)
}

fn split_top_level_commas(s: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut cur = String::new();
    let mut depth_paren = 0i32;
    let mut depth_brace = 0i32;
    for ch in s.chars() {
        match ch {
            '(' => {
                depth_paren += 1;
                cur.push(ch);
            }
            ')' => {
                depth_paren -= 1;
                cur.push(ch);
            }
            '{' => {
                depth_brace += 1;
                cur.push(ch);
            }
            '}' => {
                depth_brace -= 1;
                cur.push(ch);
            }
            ',' | '\n' if depth_paren == 0 && depth_brace == 0 => {
                if !cur.trim().is_empty() {
                    parts.push(cur.clone());
                }
                cur.clear();
            }
            _ => cur.push(ch),
        }
    }
    if !cur.trim().is_empty() {
        parts.push(cur);
    }
    parts
}

fn starts_with(chars: &[char], i: usize, word: &str) -> bool {
    let w: Vec<char> = word.chars().collect();
    if i + w.len() > chars.len() {
        return false;
    }
    chars[i..i + w.len()] == w
        && (i + w.len() == chars.len() || !chars[i + w.len()].is_alphanumeric())
}

fn require_field(map: &HashMap<String, String>, key: &str) -> Result<String, String> {
    map.get(key)
        .map(|s| normalize_atom(s))
        .ok_or_else(|| format!("missing field `{key}`"))
}

fn normalize_atom(raw: &str) -> String {
    let raw = raw.trim().trim_end_matches(',');
    if let Some(inner) = raw.strip_prefix('"').and_then(|s| s.strip_suffix('"')) {
        return inner.to_string();
    }
    raw.to_string()
}

fn normalize_memory(raw: &str) -> String {
    normalize_atom(raw)
}

fn parse_bool(s: &str) -> Result<bool, String> {
    match s {
        "true" => Ok(true),
        "false" => Ok(false),
        _ => Err(format!("expected true/false, got {s:?}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;

    fn fixture(name: &str) -> String {
        let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        p.pop();
        p.pop();
        p.push("custom");
        p.push(name);
        p.push("infra/docker.rice");
        fs::read_to_string(&p).unwrap_or_else(|e| panic!("read {}: {e}", p.display()))
    }

    #[test]
    fn memory_to_maxmemory() {
        assert_eq!(memory_limit_to_maxmemory("512M"), "512mb");
        assert_eq!(memory_limit_to_maxmemory("1G"), "1gb");
    }

    #[test]
    fn parse_egos_docker_rice() {
        let cfg = parse_docker_rice(&fixture("egos.app")).unwrap();
        assert_eq!(cfg.db_name, "egos.app");
        assert_eq!(cfg.redis_maxmemory.as_deref(), Some("512mb"));
        assert_eq!(cfg.postal_profile, "_disabled");
        let o = cfg.ollama.as_ref().unwrap();
        assert_eq!(o.max_models, 1);
        assert_eq!(o.keep_alive, "-1");
        assert!(o.roles.contains_key("think"));
        assert_eq!(cfg.bot.fallback_chain, vec!["ollama"]);
    }

    #[test]
    fn parse_code_rice_docker_rice() {
        let cfg = parse_docker_rice(&fixture("code-rice.com")).unwrap();
        assert!(cfg.ollama.is_none());
        let v = cfg.vllm.as_ref().unwrap();
        assert!(v.enable_lora);
        assert_eq!(v.model, "Qwen/Qwen2.5-7B-Instruct");
        assert_eq!(cfg.bot.fallback_chain, vec!["vllm"]);
    }

    #[test]
    fn render_project_cue_has_schema_merge() {
        let cfg = parse_docker_rice(&fixture("egos.app")).unwrap();
        let out = render_project_cue("egos", &cfg);
        assert!(out.contains("projectParams: #DockerParams &"));
        assert!(out.contains("maxmemory:   \"512mb\""));
    }
}
