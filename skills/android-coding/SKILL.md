---
name: android-coding
description: Android/Kotlin/Compose coding rules — modular architecture, ViewModel scope, Material 3, Compose pitfalls, strings, navigation, network safety, and build hygiene. Layered on top of `guardrails`.
version: 0.1.0
triggers:
  - "android"
  - "kotlin"
  - "compose"
  - "/android-coding"
globs:
  - "**/*.kt"
  - "**/*.kts"
  - "**/*.proto"
  - "**/AndroidManifest.xml"
  - "**/res/**"
  - "**/build.gradle*"
---

# Android coding

Android/Kotlin/Compose rules. Apply on every file you touch in an Android project.

## 1. Scope & layering

- Assumes the `guardrails` skill is installed. This skill **extends** guardrails — it does not replace its file-size, VCS, or build-warning rules.
- Where this skill specifies a tighter limit (e.g. file size for Kotlin), this skill wins for the matching file types.

## 2. File size — Android override

- **Kotlin `*.kt` / `*.kts`: hard ceiling 1,000 lines.** Tighter than guardrails' 1,500 to keep Compose files reviewable and recompositions easy to reason about. (A separate per-method bytecode concern is covered in §13 — line count is only a rough proxy for that.)
- When a ViewModel would exceed the limit, extract pure logic into a companion `<Name>Logic.kt` or extension file in the same package.
- Repositories: split by domain concern (CRUD, queries, styling, etc.) rather than one monolith.

## 3. Modular architecture

- Guardrails already covers feature-vs-layer organization and the `components/` / `common/` split. The Android-specific shape on top of that:
- A feature directory co-locates its Screen and ViewModel: `feature/<name>/<Name>Screen.kt`, `feature/<name>/<Name>ViewModel.kt`.
- Sub-composables used by one screen live in `feature/<name>/components/`. The screen file should not be a 1,000-line wall of composables.
- Soft preference: isolate classes that touch Android-specific APIs (`Context`, `PackageManager`, `LocationManager`, `WorkManager`, etc.) behind a small interface in the feature/repository layer. Keeps the surface easy to fake in tests and easier to swap if the project ever moves to Compose Multiplatform. Don't over-engineer — one interface + one Android impl is plenty.

## 4. ViewModel scope

- Each route gets its **own** ViewModel via `koinViewModel()` or `hiltViewModel()`.
- **Never** pass a ViewModel as a parameter to another route or down the composable tree.
- Pass only stable, serializable data across routes (`itemId`, `pageId`, `userId`). The destination loads what it needs from the repository.
- Passing a VM down causes lifecycle bugs: the parent's state clears when it leaves composition → child screens go blank.

```kotlin
// ❌ WRONG — tight coupling, blank-screen bugs
EditFlow(itemId = id, navController = nav, parentViewModel = parentViewModel)

// ✅ CORRECT — destination owns its VM and loads from repository
@Composable
fun EditFlow(itemId: String, navController: NavController) {
    val viewModel: EditFlowViewModel = koinViewModel()
    LaunchedEffect(itemId) { viewModel.loadForEdit(itemId) }
}
```

## 5. UI state pattern

- One `UiState` per screen — a `sealed class` for distinct phases (Loading/Success/Error) or a `data class` for a flat state bag.
- ViewModel exposes `StateFlow<UiState>` (never `MutableStateFlow` to the UI).
- UI collects via `collectAsStateWithLifecycle()` — never `collectAsState()` for screen state.
- Events flow up via callbacks (`onSave: (Item) -> Unit`), not by handing the VM back down.

## 6. Dependency Injection

- Use whichever DI framework the project already uses (Koin or Hilt). **Never migrate between them** without an explicit user request — it touches every module.
- In Compose, obtain ViewModels via the retrieval helper (`koinViewModel()` / `hiltViewModel()`). Do not instantiate them with `ViewModel()` directly or pass a constructed instance down the composable tree. (With Hilt, the VM itself is still `@HiltViewModel class … @Inject constructor(...)` — the helper just retrieves the scoped instance.)

## 7. UI — Material 3 only

- Always `androidx.compose.material3.*`. **Never** `androidx.compose.material.*` (Material 2).
- When M3 doesn't meet the design, build a custom composable from Foundation / UI primitives. Don't fall back to M2.

## 8. UI — Button layout

- **Never** add `Modifier.fillMaxWidth()` to `Button`, `TextButton`, `OutlinedButton`, or any button unless the user explicitly asks. Buttons size to their content.
- In `Row` layouts use `Arrangement.spacedBy()` to control spacing.

```kotlin
// ✅ CORRECT
Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
    TextButton(onClick = {}) { Text("Cancel") }
    Button(onClick = {}) { Text("Confirm") }
}

// ❌ WRONG
Row { Button(modifier = Modifier.fillMaxWidth(), onClick = {}) { Text("Submit") } }
```

## 9. Navigation

- Use `navController.navigateUp()` instead of `popBackStack()` in `onCancel`, `onComplete`, and `BackHandler` callbacks. `popBackStack()` on the start destination can leave a blank screen.
- Debounce `BackHandler` (500 ms) — rapid back presses can pop past the start destination and blank the UI.

```kotlin
BackHandler {
    val now = System.currentTimeMillis()
    if (now - lastBackPressTime < 500L) return@BackHandler
    lastBackPressTime = now
    if (!navController.navigateUp()) onCancel()
}
```

## 10. Strings — never hardcode user-facing text

- All user-visible strings go in `app/src/main/res/values/strings.xml`. Reference via `stringResource(R.string.x)` in Compose or `@string/x` in XML.
- For count-dependent text, use `plurals.xml` and `pluralStringResource(R.plurals.x, count, count)` — never string-concatenate a count into a singular template.
- Use hierarchical names: `screen_component_description` (e.g. `settings_theme_title`).
- **Translate to every locale present in the project.** Discover them by listing `res/values-*/` directories; add the new string to each `strings.xml` (and `plurals.xml`) there.
- Do not externalize: log strings, internal IDs, URLs, file paths.

```kotlin
// ❌ WRONG
Text("Welcome")

// ✅ CORRECT
Text(stringResource(R.string.welcome_title))
```

## 11. Code style

- **Never** use fully-qualified class names inline. Always add an import and reference the short name.

## 12. Compose pitfalls

- **Avoid `LocalConfiguration.current.screenWidthDp` / `screenHeightDp`** for layout decisions. These are wrong on devices with rounded corners, edge-to-edge displays, or certain OEM ROMs. Use `BoxWithConstraints` at the top of the layout and propagate the real size via a `CompositionLocal` (e.g. `LocalViewportSize`) or function parameters.
- **Stale snapshots in `pointerInput { ... }`.** The lambda captures values at lambda-start and does not restart when props change. Wrap any value you read mid-gesture in `rememberUpdatedState` and read `.value` at use time. **Do not** add the value to `pointerInput`'s keys to "fix" staleness — that cancels in-flight gestures.
- **Gesture handlers: pass callbacks, not snapshot fields.** When a gesture handler needs to consult a mode/flag (e.g. "is the app in customization mode?"), inject it as a `() -> Boolean` callback and invoke at gesture time. A field captured at composition time may be stale when the gesture fires.
- **`LaunchedEffect` keys must cover all correlated flags.** If your effect reacts to a multi-flag state machine (e.g. `isDragging` + `isDropPending`), list **every** flag whose change should wake it. A single-flag key misses A→B→A transitions inside one snapshot frame.

## 13. JVM 64KB per-method bytecode limit

- Large `@Composable`s can hit the JVM **per-method bytecode** ceiling (~64KB). Symptom: runtime `VerifyError [0x1C0B]: unable to initialize null ref` after install — D8/R8 emits the method, but the runtime verifier rejects it post-dex. (Unrelated to the 64K *DEX method count* limit, which is solved by multidex.)
- If a composable is already near the limit, **extract any new helper or diagnostic log into a top-level `private fun`** in the same file. Top-level helpers carry their own bytecode budget. Do not nest the helper inside the composable.

## 14. Network safety — always catch

- Every network call (OkHttp, Retrofit, URL connection, Geocoder) **must** be wrapped in `try/catch`. An uncaught `IOException` on a background thread crashes the app.
- Repository methods return `Result<T>` or a typed `NetworkResult<T>` — they **never throw** out of the repository boundary.
- Any `scope.launch` that calls a network method attaches a `CoroutineExceptionHandler` as a safety net.
- Never let `IOException`, `UnknownHostException`, `SocketTimeoutException`, or `HttpException` propagate out of a repository or API class.

```kotlin
suspend fun fetchData(): Data? = withContext(Dispatchers.IO) {
    try {
        val response = okHttp.newCall(request).execute()
        if (!response.isSuccessful) return@withContext null
        parse(response)
    } catch (e: IOException) {
        Timber.w(e, "Network call failed"); null
    }
}
```

## 15. Build & dependencies

- **Never edit `.toml` files** except to add a new library entry. Never change versions of existing libraries — version bumps belong in a dedicated dependency-update change, not bundled into feature work.
- Never change the Kotlin language version or AGP version. Both touch the whole build graph and have non-obvious blast radius.
- Build-warning behavior is owned by `guardrails`.

## 16. Protobuf

- Every proto enum's first value must be `{ENUM_NAME}_UNSPECIFIED = 0`. Convert the enum name from PascalCase to UPPER_SNAKE_CASE.

```protobuf
// ✅ CORRECT
enum IconShape {
  ICON_SHAPE_UNSPECIFIED = 0;
  SQUARE = 1;
  CIRCLE = 2;
}

// ❌ WRONG — missing UNSPECIFIED, or value != 0
enum IconShape {
  SQUARE = 0;
  CIRCLE = 1;
}
```
