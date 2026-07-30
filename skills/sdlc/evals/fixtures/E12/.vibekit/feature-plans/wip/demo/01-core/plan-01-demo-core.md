# Plan: demo core

## Files to Modify

| File | Change |
|------|--------|
| `src/api/serializer.py` | New backend serializer for export |
| `src/ui/ExportScreen.kt` | New frontend screen calling the serializer |

## Implementation Phases

### Phase 1
- [ ] **1.1** Implement `serialize_config()` in `src/api/serializer.py`
- [ ] **1.2** Wire `ExportScreen.kt` to call the serializer and show progress
