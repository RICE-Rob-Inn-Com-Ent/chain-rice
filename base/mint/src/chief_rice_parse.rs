//! Shared parsing for CHIEF `rc <facet> let { … }` infra Rice files.

use std::collections::HashMap;

pub fn extract_rc_let_body(src: &str, marker: &str) -> Result<String, String> {
    let mut in_let = false;
    let mut depth = 0i32;
    let mut body = String::new();
    for line in src.lines() {
        let t = line.trim();
        if t.is_empty() || t.starts_with("//") || t.starts_with('#') {
            continue;
        }
        if !in_let {
            if t.contains(marker) {
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
        Err(format!("unclosed {marker} {{ ... }}"))
    } else {
        Err(format!("missing `{marker} {{ ... }}`"))
    }
}

pub fn parse_set_blocks(body: &str) -> Result<HashMap<String, HashMap<String, String>>, String> {
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

pub fn parse_block_fields(inner: &str) -> Result<HashMap<String, String>, String> {
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

pub fn split_top_level_commas(s: &str) -> Vec<String> {
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

pub fn require_field(map: &HashMap<String, String>, key: &str) -> Result<String, String> {
    map.get(key)
        .map(|s| normalize_atom(s))
        .ok_or_else(|| format!("missing field `{key}`"))
}

pub fn optional_field(map: &HashMap<String, String>, key: &str, default: &str) -> String {
    map.get(key)
        .map(|s| normalize_atom(s))
        .unwrap_or_else(|| default.to_string())
}

pub fn parse_u32_field(map: &HashMap<String, String>, key: &str, default: u32) -> Result<u32, String> {
    match map.get(key) {
        None => Ok(default),
        Some(v) => normalize_atom(v)
            .parse()
            .map_err(|_| format!("`{key}` must be a positive integer")),
    }
}

pub fn normalize_atom(raw: &str) -> String {
    let raw = raw.trim().trim_end_matches(',');
    if let Some(inner) = raw.strip_prefix('"').and_then(|s| s.strip_suffix('"')) {
        return inner.to_string();
    }
    raw.to_string()
}

pub fn parse_bool(s: &str) -> Result<bool, String> {
    match s {
        "true" => Ok(true),
        "false" => Ok(false),
        _ => Err(format!("expected true/false, got {s:?}")),
    }
}

pub fn parse_name_tuple(raw: &str) -> Result<Vec<String>, String> {
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

pub fn cue_quote(s: &str) -> String {
    format!("{:?}", s)
}
