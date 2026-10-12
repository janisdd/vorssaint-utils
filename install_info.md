
# Building

for the mouse buttons: there is a small issue when adding shortcuts ... the mouse seems occupied after the first shortcut is added... disable shortcuts then you can add another one

From the repo root:


### Build & run (recommended for local work)

```
./build.sh --dev --install
```

That builds the separate Vorssaint (Developer) app, installs it to /Applications, and launches it. Needs Apple Silicon + macOS 14+, and Xcode Command Line Tools.


### Build only (no install)

```
./build.sh --dev
```

App ends up under build/stage/Vorssaint (Developer).app — open it from there, or use --install as above.


### Release-style .app + DMG

```
./build.sh                 # optimized Vorssaint.app in build/stage/
./Tools/make-dmg.sh        # dist/Vorssaint-<version>.dmg
```


### Useful extras

```
./build.sh --test                    # all unit tests
./build.sh --test-suite=pointer-input
./build/Vorssaint --selftest         # after a non-dev build
```


### Dev

You don’t need a custom name for side-by-side — use the developer build:

```
./build.sh --dev --install
```

That installs Vorssaint (Developer) (com.vorssaint.utils.dev) next to the normal Vorssaint (com.vorssaint.utils). Different bundle ID is what makes them coexist.

If you still want to rename it, edit the --dev block in build.sh:

```
if (( DEV )); then
    APP_NAME="Vorssaint (Developer)"
    EXECUTABLE="VorssaintDeveloper"
    APP_BUNDLE_ID="com.vorssaint.utils.dev"
    BUILD_VARIANT_FLAGS=(-D VORSSAINT_DEVELOPMENT)
    APP_OPTIMIZATION_FLAGS=(-Onone)
    BUILD_CONFIGURATION="debug"
```

Change APP_NAME for the .app / Dock label. Keep APP_BUNDLE_ID different from com.vorssaint.utils (and preferably unique) so permissions and preferences don’t collide with the release app.