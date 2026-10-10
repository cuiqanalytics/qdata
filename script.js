(() => {
  const store = {
    get: (k) => { try { return localStorage.getItem(k); } catch { return null; } },
    set: (k, v) => { try { localStorage.setItem(k, v); } catch { /* private mode */ } },
  };
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const root = document.documentElement;
  const saved = store.get('qdata-theme');
  if (saved === 'light' || saved === 'dark') root.dataset.theme = saved;
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  document.querySelector('.theme-toggle')?.addEventListener('click', () => {
    root.dataset.theme = isDark() ? 'light' : 'dark';
    store.set('qdata-theme', root.dataset.theme);
  });

  document.querySelectorAll('[data-tabs]').forEach((box) => {
    const tabs = [...box.querySelectorAll('[role="tab"]')];
    const select = (tab) => {
      tabs.forEach((t) => {
        const on = t === tab;
        t.setAttribute('aria-selected', on);
        t.tabIndex = on ? 0 : -1;
        document.getElementById(t.getAttribute('aria-controls')).hidden = !on;
      });
    };
    box.selectTab = select;
    tabs.forEach((t, i) => {
      t.addEventListener('click', () => { box.dataset.touched = '1'; select(t); });
      t.addEventListener('keydown', (e) => {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
        const next = tabs[(i + (e.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length];
        box.dataset.touched = '1'; select(next); next.focus();
      });
    });
    if (box.matches('.install') && /Mac|Win/.test(navigator.platform || '')) select(tabs[1]);
  });

  // Hero: alternate between the first crawl and the cached re-run until the visitor picks one.
  const board = document.querySelector('.runboard[data-tabs]');
  if (board && !reduceMotion) {
    const tabs = [...board.querySelectorAll('[role="tab"]')];
    let i = 0;
    setInterval(() => {
      if (board.dataset.touched || document.hidden) return;
      i = (i + 1) % tabs.length;
      board.selectTab(tabs[i]);
    }, 4000);
  }

  document.querySelectorAll('.copy').forEach((btn) => {
    btn.addEventListener('click', async () => {
      try { await navigator.clipboard.writeText(btn.dataset.copy); } catch {
        const ta = Object.assign(document.createElement('textarea'), { value: btn.dataset.copy });
        document.body.append(ta); ta.select(); document.execCommand('copy'); ta.remove();
      }
      btn.textContent = 'Copied'; btn.classList.add('done');
      setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('done'); }, 1600);
    });
  });
})();
