## 0.2.1

- Fixed a bug where processes created from `ProcessManager.spawn` could not
  have their `stdout`/`stderr` read through their respective getters (a runtime
  error was always thrown).

- Added `ProcessMangaer.background`, which does not forward `stdin`.

- Added `ProcessManager.headless`, which does not forward any standard I/O.

## 0.2.0

- Initial commit of...
   - `FutureOr<bool> String isExecutable(path)`.
   - `ExitCode`
   - `ProcessManager` and `Spawn`
   - `sharedStdIn` and `SharedStdIn`
   - `ansi.dart` library with support for formatting terminal output
