package function

paths: [ for _, f in files { f.path } ]
content: { for _, f in files { "\(f.path)": f.content } }

#FolderFile: {
	path:    string
	content: string
}

folder_outputs: [...#FolderFile]
folder_outputs: []
