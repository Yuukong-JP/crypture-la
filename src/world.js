/* world.js — Bagian 2/3/6/7: state game, core loop, Rank/GP, misi, hub, eksplorasi zona.
   Tanpa DOM (logika murni) — UI memanggilnya. */
(function () {
  const W = DB.world;

  const Game = {
    gp: 0,
    rank: 1,
    party: [],
    flags: { battlesWon: 0, bondCount: 0 },
    missions: {}, // id -> {state:'available'|'active'|'done'}
    log: [],
  };

  function rankInfo(r) {
    return W.ranks.find((x) => x.rank === r);
  }
  function nextRank() {
    return W.ranks.find((x) => x.rank === Game.rank + 1);
  }

  function init() {
    // 3 starter auto-Bond lewat story (Bagian 5)
    Game.party = [
      DB.makeInstance("001", 8, false), // Verduck
      DB.makeInstance("003", 8, false), // Pyruff
      DB.makeInstance("005", 8, false), // Ripplet
    ];
    Game.party.forEach((p) => {
      Codex.add(p.cid, 100);
      Codex.addBonded(p);
    });
    W.missions.forEach((m) => (Game.missions[m.id] = m.rank_req <= Game.rank ? "available" : "locked"));
    Game.missions["m_intro"] = "active";
  }

  function addGP(amount, why) {
    Game.gp += amount;
    Game.log.push(`+${amount} GP — ${why}`);
    checkRankUp();
  }

  function checkRankUp() {
    let leveled = null;
    let nr = nextRank();
    while (nr && !nr.placeholder && Game.gp >= nr.gp_required) {
      Game.rank = nr.rank;
      leveled = nr;
      // buka misi baru
      W.missions.forEach((m) => {
        if (Game.missions[m.id] === "locked" && m.rank_req <= Game.rank) Game.missions[m.id] = "available";
      });
      nr = nextRank();
    }
    return leveled;
  }

  // dipanggil setelah event untuk update progres misi & beri GP
  function onBattleResult(battle) {
    const events = [];
    if (battle.result === "win" || battle.result === "bond") {
      Game.flags.battlesWon++;
    }
    if (battle.result === "bond") {
      Game.flags.bondCount++;
      const inst = battle.bondedInstance;
      // versi ter-Bond lebih jinak (bukan wild_multiplier) — buat ulang non-wild
      const tamed = DB.makeInstance(inst.cid, inst.level, false);
      Codex.addBonded(tamed);
      events.push(`${inst.name} bergabung ke koleksi.`);
      // Codex 100% memberi GP dokumentasi
      if (Codex.get(inst.cid) >= 100) addGP(W.gp_rewards.codex_complete, `Codex ${inst.name} 100%`);
    }
    // cek goal misi
    W.missions.forEach((m) => {
      if (Game.missions[m.id] !== "active") return;
      const g = m.goal;
      let done = false;
      if (g.kind === "win_any_battle" && (battle.result === "win" || battle.result === "bond")) done = true;
      if (g.kind === "bond" && battle.result === "bond" && battle.bondedInstance.cid === g.cid) done = true;
      if (g.kind === "bond_count" && Game.flags.bondCount >= g.count) done = true;
      if (g.kind === "defeat_apex" && battle.result === "win" && battle.enemy.cid === g.cid) done = true;
      if (done) {
        Game.missions[m.id] = "done";
        addGP(m.gp, `Misi: ${m.name}`);
        events.push(`✅ Misi selesai: ${m.name} (+${m.gp} GP)`);
      }
    });
    return events;
  }

  function acceptMission(id) {
    if (Game.missions[id] === "available") Game.missions[id] = "active";
  }

  function activeMissions() {
    return W.missions.filter((m) => Game.missions[m.id] === "active");
  }
  function availableMissions() {
    return W.missions.filter((m) => Game.missions[m.id] === "available");
  }

  function apexUnlocked() {
    return Game.rank >= 3;
  }

  globalThis.Game = Object.assign(Game, {
    init,
    addGP,
    onBattleResult,
    acceptMission,
    activeMissions,
    availableMissions,
    rankInfo,
    nextRank,
    apexUnlocked,
    W,
  });
})();
