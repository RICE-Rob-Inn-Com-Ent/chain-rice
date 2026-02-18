package data

// Helper functions for URL parsing and string manipulation

func splitOnce(s, sep string) []string {
	idx := -1
	for i := 0; i < len(s); i++ {
		if i+len(sep) <= len(s) && s[i:i+len(sep)] == sep {
			idx = i
			break
		}
	}
	if idx == -1 {
		return []string{s}
	}
	return []string{s[:idx], s[idx+len(sep):]}
}

func extractParam(query, key string) string {
	keyPrefix := key + "="
	for i := 0; i < len(query); i++ {
		if i+len(keyPrefix) <= len(query) && query[i:i+len(keyPrefix)] == keyPrefix {
			start := i + len(keyPrefix)
			end := start
			for end < len(query) && query[end] != '&' {
				end++
			}
			return query[start:end]
		}
		for i < len(query) && query[i] != '&' {
			i++
		}
	}
	return ""
}
