/* codex.js — Bagian 5: HOOK UTAMA. Codex 0..100% per Crypture; Bond rate = Codex %.
   Sumber: encounter / move_obs / habitat / lore (NPC, buku). info_sources dari data tiap Crypture. */
(function () {
  const State = {
    codex: {}, // cid -> %
    sourcesUsed: {}, // cid -> Set(detail) agar tiap sumber sekali pakai
    bonded: [], // daftar instance ter-Bond (koleksi)
  };

  function ensure(cid) {
    if (State.codex[cid] == null) State.codex[cid] = 0;
    if (!State.sourcesUsed[cid]) State.sourcesUsed[cid] = {};
  }

  function get(cid) {
    ensure(cid);
    return State.codex[cid];
  }
  function bondRate(cid) {
    return Math.min(100, Math.round(get(cid)));
  }

  function add(cid, amt) {
    ensure(cid);
    const before = State.codex[cid];
    State.codex[cid] = Math.min(100, before + amt);
    return State.codex[cid] - before;
  }

  // Tambah berdasarkan satu entri info_sources bertipe `type` (sekali pakai per detail).
  function addFromSource(cid, type, detailKey) {
    ensure(cid);
    const sp = DB.SPECIES[cid];
    const candidates = (sp.info_sources || []).filter((s) => s.source_type === type);
    let cand = candidates[0];
    if (detailKey) cand = candidates.find((s) => s.detail === detailKey) || cand;
    if (!cand) return 0;
    if (State.sourcesUsed[cid][cand.detail]) return 0; // sudah dipakai
    State.sourcesUsed[cid][cand.detail] = true;
    return add(cid, cand.codex_gain);
  }

  // Sumber lore dari interaksi dunia (NPC/buku) yang menyebut beberapa cid.
  function addLoreFromInteraction(interaction) {
    const out = [];
    (interaction.gives_lore_for || []).forEach((cid) => {
      const sp = DB.SPECIES[cid];
      const src = (sp.info_sources || []).find(
        (s) => s.source_type === "lore" && !State.sourcesUsed[cid][s.detail]
      );
      if (src) {
        State.sourcesUsed[cid][src.detail] = true;
        const g = add(cid, src.codex_gain);
        if (g > 0) out.push({ cid, name: sp.name, amt: g, detail: src.detail });
      }
    });
    return out;
  }

  function isBonded(cid) {
    return State.bonded.some((b) => b.cid === cid);
  }
  function addBonded(instance) {
    State.bonded.push(instance);
  }

  function discovered() {
    return Object.keys(State.codex).filter((c) => State.codex[c] > 0);
  }

  globalThis.Codex = {
    State,
    get,
    add,
    bondRate,
    addFromSource,
    addLoreFromInteraction,
    isBonded,
    addBonded,
    discovered,
    ensure,
  };
})();
