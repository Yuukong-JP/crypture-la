/* Node test harness: muat data + semua modul tanpa browser, lalu simulasikan.
   Verifikasi build-order langkah 1-3: data/loader, battle, codex/bond, world/loop. */
const fs = require("fs");
const vm = require("vm");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
function load(rel) {
  vm.runInThisContext(fs.readFileSync(path.join(ROOT, rel), "utf8"), { filename: rel });
}

// data eksternal -> globalThis.GAME_DATA
const data = {};
for (const n of ["types", "moves", "crypture", "world"])
  data[n] = JSON.parse(fs.readFileSync(path.join(ROOT, "data", n + ".json"), "utf8"));
globalThis.GAME_DATA = data;

["src/loader.js", "src/codex.js", "src/battle.js", "src/world.js"].forEach(load);

let fail = 0;
function ok(cond, msg) {
  console.log((cond ? "  ok  " : " FAIL ") + msg);
  if (!cond) fail++;
}

console.log("\n== Langkah 1: data + loader ==");
ok(DB.TYPES.length === 10, "10 tipe inti dimuat");
ok(DB.typeMult("Ember", ["Nature"]) === 2.0, "Ember vs Nature = 2.0 (dari data)");
ok(DB.typeMult("Nature", ["Ember"]) === 0.5, "Nature vs Ember = 0.5");
ok(DB.typeMult("Normal", ["Nature"]) === 1.0, "Basic/Normal selalu 1.0");
ok(Object.keys(DB.SPECIES).length === 9, "9 Crypture ter-index");
const cap = DB.makeInstance("010", 7, true);
ok(cap.maxHp > 0 && cap.moves.length === 2, "instance Cappin: maxHp & 2 move (basic+natural)");
const capTame = DB.makeInstance("010", 7, false);
ok(cap.stats.hp > capTame.stats.hp, "wild_multiplier: versi liar > versi Bond (Bagian 4 LOCKED)");

console.log("\n== Langkah 3: Codex -> Bond ==");
Codex.add("010", 0);
ok(Codex.bondRate("010") === 0, "Codex Cappin mulai 0%");
Codex.addFromSource("010", "encounter");
Codex.addFromSource("010", "move_obs");
const loreEvents = Codex.addLoreFromInteraction({ gives_lore_for: ["010"] });
ok(Codex.get("010") > 0, "Codex terisi dari encounter+move_obs+lore");
// isi sampai 100 utk Bond pasti
DB.SPECIES["010"].info_sources.forEach((s) => Codex.addFromSource("010", s.source_type, s.detail));
Codex.addLoreFromInteraction({ gives_lore_for: ["010"] });
ok(Codex.bondRate("010") === 100, "Codex penuh -> bond rate 100% (Bond dijamin)");

console.log("\n== Langkah 2: Battle (simulasi 200x) ==");
function simulate(playerCids, enemyCid, enemyLvl) {
  const party = playerCids.map((c) => DB.makeInstance(c, 8, false));
  const enemy = DB.makeInstance(enemyCid, enemyLvl, !DB.SPECIES[enemyCid].apex_rules);
  const b = new BattleEngine.Battle(party, enemy);
  let guard = 0;
  while (!b.over && guard++ < 300) {
    if (b.pending) {
      const u = b.pending;
      const skill = u.moves[1];
      const lowAlly = b.alivePlayers().some((p) => p.hp / p.maxHp < 0.45);
      // Seeker potion bila ada yg kritis & cooldown siap
      if (b.alivePlayers().some((p) => p.hp / p.maxHp < 0.3) && b.seekerCd === 0) {
        b.seekerAction("potion");
      } else if (skill && skill.effect && skill.effect.kind === "heal" && lowAlly) {
        b.playerMove(skill); // support menyembuhkan
      } else {
        const mv = skill && skill.power > 0 ? skill : u.moves[0];
        b.playerMove(mv);
      }
    }
  }
  return { result: b.result, rounds: b.round };
}
let wins = 0,
  totalRounds = 0;
for (let i = 0; i < 200; i++) {
  const r = simulate(["001", "003", "005"], "011", 7); // tim seimbang vs Glimmoth (Lumen, netral)
  if (r.result === "win") wins++;
  totalRounds += r.rounds;
}
ok(wins >= 140, `Tim 3 menang ${wins}/200 vs wild Common (harusnya mayoritas)`);
ok(totalRounds / 200 >= 3 && totalRounds / 200 <= 12, `Rata-rata ronde ${(totalRounds / 200).toFixed(1)} (target 3-12, tak instan/tak molor)`);

// Apex menguji KUALITAS strategi (Bagian 4 LOCKED), bukan kecocokan tim:
// main asal-serang harus sering kalah; main pintar (heal + potion) harus sering menang.
function simulateApex(smart) {
  const party = ["001", "003", "005"].map((c) => DB.makeInstance(c, 8, false));
  const enemy = DB.makeInstance("099", 14, false);
  const b = new BattleEngine.Battle(party, enemy);
  let g = 0;
  while (!b.over && g++ < 400) {
    if (!b.pending) continue;
    const u = b.pending;
    const skill = u.moves[1];
    if (smart && b.alivePlayers().some((p) => p.hp / p.maxHp < 0.3) && b.seekerCd === 0) b.seekerAction("potion");
    else if (smart && skill && skill.effect && skill.effect.kind === "heal" && b.alivePlayers().some((p) => p.hp / p.maxHp < 0.45)) b.playerMove(skill);
    else b.playerMove(skill && skill.power > 0 ? skill : u.moves[0]);
  }
  return b.result;
}
let naive = 0,
  smart = 0;
for (let i = 0; i < 100; i++) {
  if (simulateApex(false) === "win") naive++;
  if (simulateApex(true) === "win") smart++;
}
ok(naive < 55, `Apex menghukum main asal-serang: winrate naif ${naive}/100 (harus minoritas)`);
ok(smart > 70, `Apex bisa ditaklukkan dgn strategi (heal+potion): winrate pintar ${smart}/100`);
ok(smart - naive >= 25, `Strategi berpengaruh nyata: selisih ${smart - naive} poin`);
console.log(`    (info) Apex winrate — naif ${naive}% vs pintar ${smart}%`);

console.log("\n== Loop: GP -> Rank ==");
Game.init();
ok(Game.party.length === 3 && Codex.isBonded("001"), "Start: 3 starter auto-Bond");
ok(Game.rank === 1, "Mulai Rank 1 Wanderer");
Game.addGP(90, "tes");
ok(Game.rank === 2, "GP 90 -> naik ke Rank 2 Trailblazer");
Game.addGP(150, "tes");
ok(Game.rank === 3, "GP 240 -> Rank 3 Pathfinder (buka Eldergrove)");
ok(Game.apexUnlocked(), "Apex terbuka di Rank 3");

console.log(`\n${fail === 0 ? "SEMUA LULUS ✅" : fail + " GAGAL ❌"}`);
process.exit(fail ? 1 : 0);
