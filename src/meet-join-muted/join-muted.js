// Turn mic and camera off once, as soon as Meet renders its toggle buttons (pre-join screen).
const want = [/microphone/i, /camera/i];
const done = new Set();
const obs = new MutationObserver(() => {
  for (const b of document.querySelectorAll('[data-is-muted]')) {
    const label = b.getAttribute('aria-label') || '';
    const re = want.find(r => r.test(label));
    if (!re || done.has(re)) continue;
    if (b.dataset.isMuted === 'false') b.click();
    done.add(re);
  }
  if (done.size === want.length) obs.disconnect();
});
obs.observe(document.body, { childList: true, subtree: true, attributes: true });
setTimeout(() => obs.disconnect(), 60000);
