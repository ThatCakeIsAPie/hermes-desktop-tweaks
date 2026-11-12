// btw-dismiss — adds an × to /btw side-question rows in the chat transcript so
// a long answer can be closed without reloading the app.
//
// /btw answers are client-local `system` rows (never stored), and the SDK has no
// per-message decoration area, so this watches the transcript DOM and decorates
// matching rows. Plain ESM, loaded uncompiled by the Hermes desktop app.

import { PALETTE_AREA, host } from '@hermes/plugin-sdk'

const ID = 'btw-dismiss'
const ROW = '[data-slot="aui_system-message-root"]'
const MARK = 'data-btw-dismiss'
const HIDDEN = 'data-btw-dismissed'
const STORE_KEY = 'dismissed'
const MAX_KEYS = 200

// A /btw answer reads `[btw "question" (task)]\n…`; the acknowledgement row is
// slash output rendered as `/btw · btw <task> — answering from a conversation snapshot`.
function isBtwRow(el) {
  const text = (el.textContent || '').trimStart()

  return text.startsWith('[btw') || text.startsWith('/btw')
}

function rowKey(el) {
  // The first line carries the question and task id (`[btw "q" (task)]`), which
  // is unique; later text includes a relative timestamp that changes over time.
  const clone = el.cloneNode(true)
  clone.querySelectorAll('.btw-dismiss-x').forEach(b => b.remove())
  const firstLine = (clone.textContent || '').trimStart().split('\n')[0]

  return firstLine.replace(/\s+/g, ' ').trim().slice(0, 240)
}

export default {
  id: ID,
  name: '/btw dismiss',
  register(ctx) {
    let dismissed = new Set(ctx.storage.get(STORE_KEY, []) || [])

    const save = () => {
      const keys = [...dismissed].slice(-MAX_KEYS)
      dismissed = new Set(keys)
      ctx.storage.set(STORE_KEY, keys)
    }

    const style = document.createElement('style')
    style.textContent = `
      ${ROW}[${MARK}] { position: relative; padding-right: 1.75rem !important; }
      ${ROW}[${HIDDEN}] { display: none !important; }
      .btw-dismiss-x {
        position: absolute; top: 0.125rem; right: 0.125rem;
        width: 1.25rem; height: 1.25rem; padding: 0;
        display: inline-flex; align-items: center; justify-content: center;
        border: 0; border-radius: 0.25rem; background: transparent; cursor: pointer;
        color: var(--ui-text-tertiary, currentColor); font-size: 0.875rem; line-height: 1;
        opacity: 0.6;
      }
      .btw-dismiss-x:hover {
        opacity: 1; color: var(--ui-text-primary, currentColor);
        background: var(--chrome-action-hover, transparent);
      }
    `
    document.head.appendChild(style)

    const decorate = row => {
      if (!isBtwRow(row)) return

      const key = rowKey(row)

      if (dismissed.has(key)) {
        row.setAttribute(HIDDEN, '')

        return
      }

      if (row.hasAttribute(MARK) && row.querySelector(':scope > .btw-dismiss-x')) return

      row.setAttribute(MARK, '')
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'btw-dismiss-x'
      button.title = 'Dismiss this /btw message'
      button.setAttribute('aria-label', 'Dismiss this /btw message')
      button.textContent = '×'
      button.addEventListener('click', event => {
        event.preventDefault()
        event.stopPropagation()
        dismissed.add(key)
        save()
        row.setAttribute(HIDDEN, '')
      })
      row.appendChild(button)
    }

    const scan = () => document.querySelectorAll(ROW).forEach(decorate)

    let queued = false
    const observer = new MutationObserver(() => {
      if (queued) return
      queued = true
      requestAnimationFrame(() => {
        queued = false
        scan()
      })
    })
    observer.observe(document.body, { childList: true, subtree: true, characterData: true })
    scan()

    ctx.register({
      id: 'restore',
      area: PALETTE_AREA,
      data: {
        id: 'btw-dismiss.restore',
        label: 'Show dismissed /btw messages',
        keywords: ['btw', 'dismiss', 'restore', 'side question'],
        run: () => {
          dismissed = new Set()
          ctx.storage.remove(STORE_KEY)
          document.querySelectorAll(`[${HIDDEN}]`).forEach(el => el.removeAttribute(HIDDEN))
          scan()
          host.notify({ kind: 'info', message: 'Dismissed /btw messages restored' })
        }
      }
    })

    ctx.onDispose(() => {
      observer.disconnect()
      style.remove()
      document.querySelectorAll('.btw-dismiss-x').forEach(el => el.remove())
      document.querySelectorAll(`[${MARK}],[${HIDDEN}]`).forEach(el => {
        el.removeAttribute(MARK)
        el.removeAttribute(HIDDEN)
      })
    })
  }
}
