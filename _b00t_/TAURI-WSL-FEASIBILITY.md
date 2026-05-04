# Tauri/WSL Feasibility Assessment

## Environment

- Host: WSL2 (Windows) → SSH → Ubuntu 22.04 LTS (sm3llyd0s)
- DISPLAY: `localhost:10.0` (X11 forwarding active)
- Rust: 1.91.1
- Node: 22.16.0

## Dependencies Audit

| Package | Status | Required For |
|---------|--------|--------------|
| libgtk-3-0 | ✅ installed | GTK base |
| libwebkit2gtk-4.1-dev | ❌ missing | Tauri v2 webview |
| libjavascriptcoregtk-4.1-dev | ❌ missing | Tauri v2 JS engine |
| libsoup-3.0-dev | ❌ missing | Tauri v2 networking |
| libappindicator3-dev | ❌ missing | Tauri system tray |

## Installation Command

```bash
sudo apt update
sudo apt install -y libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev libsoup-3.0-dev libappindicator3-dev
```

## X11 Forwarding

- SSH client on WSL must have `ForwardX11 yes`
- Tauri window will render on WSL host's X server
- Performance: acceptable for dev; use WebGL carefully over X11

## Recommendation

1. **Short-term**: Use existing embedded HTTP server (`cbm-with-ui` target). Browser on WSL opens `http://localhost:9749` via SSH tunnel.
2. **Medium-term**: Install webkit2gtk deps and scaffold Tauri wrapper around `graph-ui/dist`.
3. **Long-term**: Tauri app bundles l3dg3rr binary + UI, distributed as `.deb` / `.msi`.

## Blockers

- ⚠️ webkit2gtk compile time ~10-15 min on first build
- ⚠️ X11 over SSH adds latency; prefer running Tauri on WSL host directly
- ⚠️ l3dg3rr is pure C; Tauri would be a separate Rust wrapper crate

<!-- b00t:map v1
summary: Tauri on WSL feasibility for l3dg3rr docgen UI
tags: tauri, wsl, l3dg3rr, gui, webkit2gtk
tier: frontier
cmds: sudo apt install libwebkit2gtk-4.1-dev, cargo tauri dev
complexity: 5
-->
