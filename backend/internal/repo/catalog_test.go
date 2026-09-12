package repo

import "testing"

// The embedded seed is the one thing here that can rot silently — a typo in the
// JSON only shows up as a boot failure otherwise.
func TestSeedCatalog(t *testing.T) {
	items, err := catalogSeedItems()
	if err != nil {
		t.Fatalf("seed json: %v", err)
	}
	if len(items) < 50 {
		t.Fatalf("expected the full food table, got %d rows", len(items))
	}
	seen := map[string]bool{}
	for _, it := range items {
		if it.ID == "" || it.Name == "" || it.Serving == "" || it.Calories <= 0 {
			t.Fatalf("incomplete row: %+v", it)
		}
		if seen[it.ID] {
			t.Fatalf("duplicate id %q", it.ID)
		}
		seen[it.ID] = true
	}
}
