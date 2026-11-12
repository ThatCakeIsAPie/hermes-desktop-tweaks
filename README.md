# Hermes desktop tweaks

Small plugins for the [Hermes](https://github.com/NousResearch/hermes-agent) desktop app.
Each is one `plugin.js` with no build step.

| Plugin | What it does |
| --- | --- |
| `btw-dismiss` | Adds an × to `/btw` side-question rows in a chat so a long answer can be closed. **Show dismissed /btw messages** in the command palette brings them back. |
| `grokbot-tweaks` | Adjusts the Grokbot Override screen from [Hermes Bot Kit](https://github.com/thomasbek3/hermes-bot-kit): hides the Share button in the chat header and makes the backgrounds follow the Hermes theme. CSS only. |

## Install

```sh
./install.sh                  # all plugins
./install.sh grokbot-tweaks   # only the named ones
```

The script copies each plugin to `~/.hermes/desktop-plugins/<name>/plugin.js`
(`$HERMES_HOME/desktop-plugins` when that is set). The app loads a new file within a
few seconds and hot-reloads later changes. If one does not appear, run **Reload desktop
plugins** from the command palette.

To change a plugin, edit it here and run `./install.sh` again.

## Notes

- `grokbot-tweaks` needs Grokbot Override installed and does nothing without it. It was
  written against Hermes Bot Kit v2026.11.10.4 and matches that version's class names, so
  a later Bot Kit release may need the selectors updated.
- `btw-dismiss` finds `/btw` rows by the text Hermes renders, because the plugin SDK has no
  per-message hook. A Hermes update that changes that text may need the plugin updated.
- Changes to Hermes itself live in a separate fork, on its `dispatcher-ui` branch.
