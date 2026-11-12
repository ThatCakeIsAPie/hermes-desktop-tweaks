// grokbot-tweaks — local adjustments to Hermes Bot Kit's Grokbot Override
// (~/.hermes/desktop-plugins/grokbot-override), kept in their own plugin so a
// kit update does not undo them. CSS only: nothing here reads or sends chat
// content. Turn it off in Settings → Plugins to get the kit's stock look back.
//
// Plain ESM, loaded uncompiled by the Hermes desktop app.

const ID = 'grokbot-tweaks'
const VERSION = '1'
const STYLE_ID = 'grokbot-tweaks-style'

// The override scopes everything under [data-gbo-root] (menus and popovers
// carry the attribute too) and sets its palette at up to two-class
// specificity, so `:root [data-gbo-root][data-gbo-root]` wins without
// !important and regardless of which stylesheet loads first.
const SCOPE = ':root [data-gbo-root][data-gbo-root]'

export const CSS = `
/* 1. No Share button in the chat header. Its menu held one entry ("Open
      another chat beside this one"). The group-chat Stop button reuses the
      .share-btn class, so match the label, not the class alone. */
[data-gbo-root] button.share-btn[aria-label="Share"],
[data-gbo-root] span:has(> button.share-btn[aria-label="Share"]) {
  display: none !important;
}

/* 2. Backgrounds follow the Hermes theme (the Omarchy skin) instead of the
      kit's fixed white / near-black. Same surface tokens stock Hermes paints
      its chat, sidebar and raised cards with, so glass and translucency modes
      behave the same. Text, borders and bot colours stay the kit's own: its
      light/dark switch already follows the theme. */
${SCOPE} {
  /* chat */
  --color-bg-pane: var(--ui-chat-surface-background);
  --gbo-bg: var(--ui-chat-surface-background);
  /* roster */
  --color-bg-sidebar: var(--ui-sidebar-surface-background);
  --gbo-sidebar: var(--ui-sidebar-surface-background);
  /* profile panel and window chrome */
  --color-bg-chrome: var(--ui-bg-chrome);
  --gbo-panel-bg: var(--ui-bg-chrome);
  /* raised: cards, menus, composer, header pills */
  --color-bg-elevated: var(--ui-bg-elevated);
  --gbo-card: var(--ui-bg-elevated);
  --gbo-popover: var(--ui-bg-elevated);
  --gbo-surface: var(--ui-bg-elevated);
  --gbo-chrome-bg: var(--ui-bg-elevated);
  --gbo-composer-bg: var(--ui-bg-elevated);
  /* solid fills the kit hard-codes as greys: tint the themed surface with
     the theme's text colour by the same small steps */
  --color-bg-elevated-hover: color-mix(in srgb, var(--ui-base) 8%, var(--ui-bg-elevated));
  --color-bg-active-solid: color-mix(in srgb, var(--ui-base) 9%, var(--ui-bg-chrome));
  --color-bubble-agent-flat: color-mix(in srgb, var(--ui-base) 8%, var(--ui-bg-chrome));
  --color-code-block: color-mix(in srgb, var(--ui-base) 4%, var(--ui-bg-chrome));
  --color-row-selected-solid: color-mix(in srgb, var(--ui-base) 9%, var(--ui-bg-sidebar));
  --color-row-hover-solid: color-mix(in srgb, var(--ui-base) 5%, var(--ui-bg-sidebar));
}
`

export default {
  id: ID,
  name: 'Grokbot tweaks',
  register(ctx) {
    document.getElementById(STYLE_ID)?.remove()

    const style = document.createElement('style')
    style.id = STYLE_ID
    style.textContent = CSS
    document.head.appendChild(style)

    // Version stamp: lets a load be confirmed from the app's storage.
    ctx.storage?.set?.('version', VERSION)

    ctx.onDispose(() => style.remove())
  }
}
