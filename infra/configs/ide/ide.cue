package ide

// Multi-IDE template (.cursor, .windsurf, .continue, .claude).
// Future exports can target paths such as:
//   Output: .cursor/mcp.json
//   Output: .windsurf/rules/...
//   Output: .continue/rules/...
//   Output: .claude/agents/...

cursor: mcpJson: string | *"{}"
windsurf: rulesReadme: string | *""
continueIde: rulesReadme: string | *""
claude: agentsReadme: string | *""

paths: []
content: {}
folder_outputs: [...#FolderFile]
folder_outputs: []

#FolderFile: {
	path:    string
	content: string
}
