package greeter

import "testing"

func TestGreet(t *testing.T) {
	if got := Greet("World"); got != "Hello, World!" {
		t.Fatalf("expected 'Hello, World!' got %q", got)
	}
	if got := Greet(""); got != "Hello, World!" {
		t.Fatalf("expected default to 'Hello, World!' got %q", got)
	}
}
