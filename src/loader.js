/* loader.js — Data Spec 8: data eksternal -> objek runtime.
   Membangun type chart penuh dari entri non-1.0, mengindeks Crypture & Move,
   dan menyediakan helper menghitung stat berdasarkan level + growth_curve. */
(function () {
  const DB = globalThis.GAME_DATA;

  // ---- Type chart: isi default 1.0 untuk semua pasangan ----
  const TYPES = DB.types.types.slice();
  const chart = {};
  TYPES.concat(["Normal"]).forEach((atk) => {
    chart[atk] = {};
    TYPES.concat(["Normal"]).forEach((def) => (chart[atk][def] = 1.0));
  });
  for (const atk in DB.types.chart) {
    for (const def in DB.types.chart[atk]) chart[atk][def] = DB.types.chart[atk][def];
  }

  function typeMult(moveType, defenderTypes) {
    if (!moveType || moveType === "Normal") return 1.0;
    let m = 1.0;
    for (const t of defenderTypes) m *= chart[moveType] ? (chart[moveType][t] ?? 1.0) : 1.0;
    return m;
  }

  // ---- Index ----
  const MOVES = DB.moves.moves;
  const SPECIES = {};
  DB.crypture.crypture.forEach((c) => (SPECIES[c.id] = c));

  function statAt(species, key, level) {
    const base = species.base_stats[key] || 0;
    const g = (species.growth_curve && species.growth_curve[key]) || 0;
    return Math.round(base + g * (level - 1));
  }

  // Bangun instance Crypture (dipakai battle/world). isWild menerapkan wild_multiplier.
  let uid = 0;
  function makeInstance(cid, level, isWild) {
    const sp = SPECIES[cid];
    const mult = isWild ? sp.wild_multiplier || 1.0 : 1.0;
    const s = {};
    ["hp", "atk", "def", "sp_atk", "sp_def", "speed"].forEach(
      (k) => (s[k] = Math.round(statAt(sp, k, level) * mult))
    );
    const maxHp = Math.round(s.hp * 2.4);
    const abilities = (sp.abilities || []).filter((a) => a.unlock_level <= level).map((a) => a.id);
    return {
      uid: ++uid,
      cid,
      name: sp.name,
      species: sp,
      level,
      isWild: !!isWild,
      types: sp.types,
      role: sp.role,
      stats: s,
      maxHp,
      hp: maxHp,
      moves: [MOVES.basic_strike, MOVES[sp.natural_skill.move]]
        .concat((sp.extra_moves || []).map((m) => MOVES[m]))
        .filter(Boolean),
      abilities,
      status: null, // 'burn' | 'sleep'
      statStages: { atk: 0, def: 0, sp_atk: 0, sp_def: 0, speed: 0 },
      taunt: 0,
      enraged: false,
    };
  }

  globalThis.DB = {
    raw: DB,
    TYPES,
    chart,
    typeMult,
    MOVES,
    SPECIES,
    world: DB.world,
    colors: DB.types.colors,
    statAt,
    makeInstance,
  };

  // ---- Validasi ringan: Test build-order langkah 1 ----
  let warns = 0;
  DB.crypture.crypture.forEach((c) => {
    c.types.forEach((t) => {
      if (!TYPES.includes(t)) console.warn("Tipe tak dikenal", t, "pada", c.id), warns++;
    });
    if (!MOVES[c.natural_skill.move]) console.warn("natural_skill hilang", c.id), warns++;
  });
  console.log(
    `[loader] ${DB.crypture.crypture.length} Crypture, ${Object.keys(MOVES).length} move, ${TYPES.length} tipe. ${warns} peringatan.`
  );
})();
