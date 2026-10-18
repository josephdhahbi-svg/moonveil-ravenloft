/* Read-only canonical campaign sheet. Never imports or overwrites browser saves. */
(() => {
  'use strict';
  const section = document.getElementById('character');
  if (!section) return;
  const panel = document.createElement('div');
  panel.className = 'panel';
  panel.setAttribute('aria-label', 'Verified Moonveil reference sheet');
  panel.innerHTML = '<h2>Verified campaign reference</h2><p class="muted">Loading source data. This reference does not replace your save.</p>';
  section.append(panel);
  const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({
    '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'
  }[char]));
  fetch('./data/moonveil_verified_context.json', {cache:'no-store'})
    .then(response => {
      if (!response.ok) throw Error('reference unavailable');
      return response.json();
    })
    .then(data => {
      const c = data.campaign;
      if (!c || c.id !== 'vesper' || c.character_id !== 'vesper-vane') {
        throw Error('reference campaign mismatch');
      }
      const line = (label, value) => '<p><strong>' + escapeHtml(label) +
        ':</strong> ' + escapeHtml(value) + '</p>';
      panel.innerHTML = '<h2>Verified campaign reference · read-only</h2>' +
        line('Character', c.name + ' · ' + c.ancestry + ' ' + c.class) +
        line('Patron', c.patron) + line('Faith', c.faith) +
        line('Level', c.level + '/' + c.max_level) +
        line('HP / AC', c.hp + '/' + c.max_hp + ' · AC ' + c.armor_class) +
        line('Pact slots', c.pact_slots + '/' + c.max_pact_slots) +
        line('Checkpoint', c.location + ' · Link ' + c.link + ' · Sector ' + c.sector) +
        line('Relics (reference only)', c.relics.join(', ')) +
        line('Quest items (reference only)', c.quest_items.join(', ')) +
        '<p class="muted">This sheet is source reference, not proof of items in your browser save. No save data was changed.</p>';
    })
    .catch(() => {
      panel.innerHTML = '<h2>Verified campaign reference</h2>' +
        '<p class="muted">Reference data is unavailable. Your existing save is unchanged.</p>';
    });
})();
