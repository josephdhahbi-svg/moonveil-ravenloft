/* Moonveil cross-module navigation and save isolation diagnostics.
   Read-only: no imported save, item, character or campaign state is modified. */
(() => {
  'use strict';
  const modules = [
    {label:'Vesper Adventure', path:'index.html', key:'moonveil_ravenloft_portable_v1'},
    {label:'Living World', path:'living-world.html', key:'moonveil-living-world-v1'},
    {label:'Faction War', path:'faction-war.html', key:'moonveil-faction-war-v1'},
    {label:'Adventure War Room', path:'adventure-war-room.html', key:'moonveil-adventure-war-room-v1'},
    {label:'Tactical War Table', path:'tactical-war-table.html', key:'moonveil-tactical-war-v1'}
  ];
  const panel = document.createElement('details');
  panel.style.cssText = 'position:relative;max-width:1250px;margin:12px auto;padding:12px;border:1px solid #79619d;border-radius:12px;background:#1c1730;color:#f3eaff;font:14px system-ui';
  panel.innerHTML = '<summary style="cursor:pointer">🌌 Moonveil connected modules · local save diagnostics</summary><div id="moonveil-module-status" style="display:grid;gap:8px;margin-top:12px"></div><p style="opacity:.75">Modules are linked, not yet synchronized. Existing saves remain separate and untouched.</p>';
  const target = document.querySelector('main') || document.body;
  target.insertBefore(panel, target.firstChild);
  const container = panel.querySelector('#moonveil-module-status');
  const escapeHtml = text => String(text).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function render() {
    container.replaceChildren();
    for (const item of modules) {
      const line = document.createElement('div');
      let status = 'Unknown';
      try { status = localStorage.getItem(item.key) === null ? 'No browser save found' : 'Local save present'; }
      catch { status = 'Storage unavailable'; }
      const link = document.createElement('a');
      link.href = './' + item.path;
      link.textContent = item.label;
      link.style.cssText = 'color:#e1c7ff;font-weight:bold';
      line.append(link, document.createTextNode(' · ' + status));
      container.append(line);
    }
  }
  panel.addEventListener('toggle', () => { if (panel.open) render(); });
  render();
})();
