/* Smoke test UI di Node dengan DOM tiruan (Proxy). Tak memvalidasi visual,
   tapi menangkap error runtime saat boot/render tiap screen (typo, fungsi/properti hilang). */
const fs = require("fs"),
  vm = require("vm");

const data = {};
for (const n of ["types", "moves", "crypture", "world"])
  data[n] = JSON.parse(fs.readFileSync("data/" + n + ".json", "utf8"));
globalThis.GAME_DATA = data;

// ---- DOM tiruan ----
function fakeEl() {
  const node = {
    style: {},
    children: [],
    _html: "",
    set innerHTML(v) {
      this._html = v;
    },
    get innerHTML() {
      return this._html;
    },
    appendChild() {},
    querySelector() {
      return fakeEl();
    },
    querySelectorAll() {
      return [];
    },
    addEventListener() {},
    getContext() {
      return new Proxy({}, { get: () => () => {} });
    },
    get firstChild() {
      return fakeEl();
    },
    set onclick(_) {},
    set onkeydown(_) {},
  };
  return new Proxy(node, {
    get(t, p) {
      if (p in t) return t[p];
      if (p === "textContent" || p === "title" || p === "disabled" || p === "scrollTop" || p === "scrollHeight") return "";
      return fakeEl;
    },
    set() {
      return true;
    },
  });
}
globalThis.document = {
  querySelector: () => fakeEl(),
  createElement: () => fakeEl(),
  set onkeydown(_) {},
};
globalThis.setTimeout = () => 0;

["src/loader.js", "src/codex.js", "src/battle.js", "src/world.js", "src/ui.js"].forEach((f) =>
  vm.runInThisContext(fs.readFileSync(f, "utf8"), { filename: f })
);

let fail = 0;
function step(name, fn) {
  try {
    fn();
    console.log("  ok  " + name);
  } catch (e) {
    console.log(" FAIL " + name + " :: " + e.message);
    fail++;
  }
}

step("boot() -> Game.init + intro", () => UI.boot());
step("render hub()", () => UI.hub());
step("render intro()", () => UI.intro());
// exercise a full battle headlessly via engine + Game loop
step("battle resolve + onBattleResult", () => {
  const enemy = DB.makeInstance("011", 7, true);
  const b = new BattleEngine.Battle(Game.party, enemy);
  let g = 0;
  while (!b.over && g++ < 300) {
    if (b.pending) b.playerMove(b.pending.moves[1] && b.pending.moves[1].power > 0 ? b.pending.moves[1] : b.pending.moves[0]);
  }
  Game.onBattleResult(b);
});
console.log(fail === 0 ? "\nUI SMOKE OK ✅" : `\n${fail} GAGAL ❌`);
process.exit(fail ? 1 : 0);
