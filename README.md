# Hermes desktop tweaks

My setup for the [Hermes](https://github.com/NousResearch/hermes-agent) desktop app, installable on
any device with one command.

## Set up a device

Hermes must already be installed. Then, in a terminal on that device (macOS or Linux):

```sh
curl -fsSL https://raw.githubusercontent.com/ThatCakeIsAPie/hermes-desktop-tweaks/main/setup.sh | bash
```

Run it again any time to pick up new tweaks. It skips whatever is already done.

| Step | What it does |
| --- | --- |
| Bot Kit | Installs Grokbot Override from [Hermes Bot Kit](https://github.com/thomasbek3/hermes-bot-kit), release v2026.11.10.4: a chat-app style Bots screen. The Bot Kit installer is checked against a known hash before it runs. |
| Plugins | Copies the plugins in this repo into `~/.hermes/desktop-plugins/`. |
| App | Applies my changes to Hermes itself (the `dispatcher-ui` branch of [my fork](https://github.com/ThatCakeIsAPie/hermes-agent/tree/dispatcher-ui)) on top of the Hermes version the device already has, then rebuilds the desktop app. The rebuild takes about 10 minutes, and an open Hermes window closes when it finishes: reopen it. |
| Buttons | On a tiling window manager (Hyprland, sway, niri), turns off the app's own minimize, maximize and close buttons. |

Options go after `bash -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/ThatCakeIsAPie/hermes-desktop-tweaks/main/setup.sh | bash -s -- --no-app
```

| Option | Effect |
| --- | --- |
| `--plugins-only` | Only copy this repo's plugins. |
| `--no-botkit` | Skip Bot Kit. |
| `--no-app` | Skip the app changes, the rebuild and the window buttons. Takes seconds. |
| `--no-build` | Apply the app changes without rebuilding. |
| `--rebuild` | Rebuild even when nothing new was applied. |
| `--hide-window-buttons` | Turn the window buttons off on any Linux desktop. |
| `--keep-window-buttons` | Never touch the window buttons. |

## What is in here

| Plugin | What it does |
| --- | --- |
| `btw-dismiss` | Adds an × to `/btw` side-question rows in a chat so a long answer can be closed. **Show dismissed /btw messages** in the command palette brings them back. |
| `grokbot-tweaks` | Adjusts the Grokbot Override screen: hides the Share button in the chat header and makes the backgrounds follow the Hermes theme. CSS only. |

The app changes (in the fork, not in this repo):

- Each Bot's chat follows that Bot's own settings for showing tool activity and thinking.
- A Bot that hides tool activity shows background work as one line per task, "Working on: …",
  which becomes "Done: …".
- `{"hidden": true}` in `~/.config/Hermes/window-controls.json` removes the app's window buttons.

## Good to know

- **Updating Hermes afterwards.** The app changes sit on a local `dispatcher-ui` branch in
  `~/.hermes/hermes-agent`, so `main` still matches upstream. After a Hermes update, run the
  setup command again to re-apply and rebuild.
- **If a change does not apply.** The app step stops, puts the checkout back as it was and says
  which change failed. That means the device's Hermes version has moved on in the same code and the
  fork needs updating first. Bot Kit and the plugins are installed regardless.
- **Hermes installed without git** (a packaged app with no `~/.hermes/hermes-agent` checkout) gets
  Bot Kit and the plugins only.
- **Windows** is not covered by the script. Copy each `plugin.js` into
  `%USERPROFILE%\.hermes\desktop-plugins\<name>\` by hand.
- `grokbot-tweaks` matches class names from Bot Kit v2026.11.10.4, and `btw-dismiss` matches the
  text Hermes renders for `/btw` rows. A later release of either may need the plugin updated.

## Changing a plugin

Edit it in a clone of this repo, then `./setup.sh --plugins-only` copies it into the running app,
which hot-reloads it.
