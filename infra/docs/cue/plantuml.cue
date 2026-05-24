package docs

// plantuml.cue — PlantUML diagram catalog for CHIEF docs overlays.

#PlantUMLParams: {
	theme:    string | *"plain"
	diagrams: [...string] | *["architecture"]
}
