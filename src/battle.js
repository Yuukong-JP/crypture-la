/* battle.js — Bagian 4: Seeker = commander, Crypture = unit. Turn-based, turn queue by Speed.
   - Party 3 di lapangan sekaligus (3 vs 1). Type multiplier dari data.
   - HP musuh HIDDEN: band kualitatif + feedback efektivitas.
   - Aksi Seeker (potion/scan/bond) dengan cooldown — bukan tombol menang.
   - Eldergrove (Apex): tak bisa di-Bond, win = lemahkan ke ambang, fase Murka di 50%. */
(function () {
  const SCALE = 0.62; // tuning damage global (balance pass nanti)

  function stageMult(stage) {
    return stage >= 0 ? (2 + stage) / 2 : 2 / (2 - stage);
  }
  function rng(a, b) {
    return a + Math.random() * (b - a);
  }

  function hpBand(frac) {
    if (frac <= 0) return { label: "Tumbang", cls: "b-out" };
    if (frac < 0.18) return { label: "Sekarat", cls: "b-crit" };
    if (frac < 0.4) return { label: "Terluka parah", cls: "b-low" };
    if (frac < 0.7) return { label: "Terluka", cls: "b-mid" };
    if (frac < 0.95) return { label: "Masih kuat", cls: "b-ok" };
    return { label: "Segar", cls: "b-full" };
  }
  function effText(m) {
    if (m === 0) return "Tak berpengaruh...";
    if (m >= 2) return "Serangan telak!";
    if (m > 1) return "Cukup efektif.";
    if (m < 1) return "Kurang efektif...";
    return "";
  }

  function calcDamage(attacker, defender, move) {
    const physical = move.category === "Physical";
    let A = attacker.stats[physical ? "atk" : "sp_atk"] * stageMult(attacker.statStages[physical ? "atk" : "sp_atk"]);
    let D = defender.stats[physical ? "def" : "sp_def"] * stageMult(defender.statStages[physical ? "def" : "sp_def"]);
    // Ability: Kindling (atk +30% saat HP < 1/3)
    if (attacker.abilities.includes("kindling") && attacker.hp / attacker.maxHp < 1 / 3) A *= 1.3;
    const stab = attacker.types.includes(move.type) ? 1.5 : 1.0;
    const tmult = DB.typeMult(move.type, defender.types);
    let dmg = (((2 * attacker.level) / 5 + 2) * move.power * (A / D)) / 50 + 2;
    dmg *= stab * tmult * rng(0.85, 1.0) * SCALE;
    if (attacker.enraged) dmg *= 1.85; // Apex Awakening (Fase Murka)
    // Damage-reduction abilities
    if (defender.abilities.includes("bark_skin")) dmg *= 0.85;
    if (defender.abilities.includes("ancient_bark")) dmg *= 0.8;
    if (defender.abilities.includes("sturdy_hide") && physical) dmg *= 0.9;
    return { dmg: Math.max(1, Math.round(dmg)), tmult, stab };
  }

  function Battle(party, enemy, opts) {
    opts = opts || {};
    this.party = party; // array instance pemain (di lapangan)
    this.enemy = enemy; // satu instance musuh
    this.isApex = !enemy.species.bondable && enemy.species.apex_rules;
    this.log = [];
    this.round = 0;
    this.queue = [];
    this.pending = null; // unit pemain yang menunggu perintah
    this.over = false;
    this.result = null; // 'win' | 'lose' | 'bond' | 'flee'
    this.seekerCd = 0; // cooldown aksi pendukung Seeker
    this.observed = {}; // cid -> set move yang sudah terlihat (untuk Codex)
    this.bonus = { codex: [] };
    this.say(`Encounter! ${enemy.name} liar ${this.isApex ? "(APEX — tak bisa di-Bond)" : ""} muncul.`);
    this.startRound();
  }

  Battle.prototype.say = function (t) {
    this.log.push(t);
  };
  Battle.prototype.allUnits = function () {
    return this.party.concat([this.enemy]);
  };
  Battle.prototype.alivePlayers = function () {
    return this.party.filter((u) => u.hp > 0);
  };

  Battle.prototype.startRound = function () {
    this.round++;
    if (this.seekerCd > 0) this.seekerCd--;
    // bersihkan taunt habis
    this.allUnits().forEach((u) => {
      if (u.taunt > 0) u.taunt--;
    });
    // Apex Awakening
    if (this.isApex && !this.enemy.enraged && this.enemy.hp / this.enemy.maxHp <= this.enemy.species.apex_rules.phase_at) {
      this.enemy.enraged = true;
      this.say(`🌑 ${this.enemy.name} memasuki FASE MURKA — serangannya menggila!`);
    }
    this.queue = this.allUnits()
      .filter((u) => u.hp > 0)
      .sort((a, b) => b.stats.speed * stageMult(b.statStages.speed) - a.stats.speed * stageMult(a.statStages.speed));
    this.advance();
  };

  // Maju di queue sampai ketemu giliran unit pemain (butuh input) atau ronde habis.
  Battle.prototype.advance = function () {
    while (this.queue.length) {
      const u = this.queue.shift();
      if (u.hp <= 0) continue;
      if (u === this.enemy) {
        this.enemyTurn();
        if (this.over) return;
        continue;
      }
      // unit pemain: butuh perintah
      this.pending = u;
      return;
    }
    if (!this.over) this.startRound();
  };

  // ---- Aksi unit pemain ----
  Battle.prototype.playerMove = function (move, targetOverride) {
    const u = this.pending;
    if (!u) return;
    this.pending = null;
    this.useMove(u, move, targetOverride || this.enemy);
    this.tickBurn(u);
    this.afterAction();
  };

  Battle.prototype.useMove = function (actor, move, target) {
    // start-of-use status
    if (actor.status === "sleep") {
      if (Math.random() < 0.35) {
        actor.status = null;
        this.say(`${actor.name} terbangun!`);
      } else {
        this.say(`${actor.name} tertidur, tak bisa bergerak.`);
        return;
      }
    }
    // catat observasi move musuh (Codex move_obs)
    if (actor === this.enemy) this.markObserved(actor.cid, move.id);

    if (Math.random() * 100 > move.accuracy) {
      this.say(`${actor.name} memakai ${move.name} — meleset!`);
      return;
    }

    const eff = move.effect;
    if (!eff || move.category !== "Status") {
      // Damage move
      if (move.power > 0) {
        const { dmg, tmult } = calcDamage(actor, target, move);
        target.hp = Math.max(0, target.hp - dmg);
        const et = effText(tmult);
        this.say(`${actor.name} → ${move.name}. ${et}`.trim());
        if (target.hp <= 0) this.say(`${target.name} tumbang!`);
        // AoE: hantam unit pemain lain dengan skill yang sama (80% power)
        if (eff && eff.kind === "aoe") {
          this.party
            .filter((p) => p.hp > 0 && p !== target)
            .forEach((p) => {
              const r = calcDamage(actor, p, Object.assign({}, move, { power: Math.round(move.power * 0.8) }));
              p.hp = Math.max(0, p.hp - r.dmg);
              if (p.hp <= 0) this.say(`${p.name} tumbang oleh gelombang!`);
            });
          this.say(`Gelombang ${move.name} menyapu seluruh tim!`);
        }
      }
      if (eff && eff.kind !== "aoe") this.applyEffect(actor, target, eff);
    } else {
      this.say(`${actor.name} memakai ${move.name}.`);
      this.applyEffect(actor, target, eff);
    }
  };

  Battle.prototype.applyEffect = function (actor, target, eff) {
    if (!eff) return;
    const allies = actor.isWild ? [this.enemy] : this.party;
    switch (eff.kind) {
      case "buff": {
        const t = eff.target === "self" ? actor : target;
        t.statStages[eff.stat] = Math.min(6, t.statStages[eff.stat] + eff.stages);
        this.say(`${t.name}: ${eff.stat.toUpperCase()} naik.`);
        if (eff.taunt) {
          actor.taunt = eff.taunt + 1;
          this.say(`${actor.name} memancing serangan (taunt)!`);
        }
        break;
      }
      case "debuff": {
        if (target.abilities && target.abilities.includes("rooted") && eff.stat === "speed") {
          this.say(`${target.name} berakar — Speed tak terpengaruh.`);
          break;
        }
        target.statStages[eff.stat] = Math.max(-6, target.statStages[eff.stat] - eff.stages);
        this.say(`${target.name}: ${eff.stat.toUpperCase()} turun.`);
        break;
      }
      case "status": {
        if (target.species.apex_rules) {
          this.say(`Kehendak hutan ${target.name} kebal terhadap status.`);
          break;
        }
        if (Math.random() < (eff.chance || 1) && !target.status) {
          target.status = eff.status;
          this.say(`${target.name} terkena ${eff.status === "burn" ? "luka bakar" : eff.status}!`);
        }
        break;
      }
      case "heal": {
        let pool;
        if (eff.target === "self") pool = [actor];
        else pool = allies.filter((a) => a.hp > 0).sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp);
        const t = pool[0];
        if (t) {
          let amt = Math.round(t.maxHp * eff.amount);
          if (actor.abilities.includes("tidecaller")) amt = Math.round(amt * 1.15);
          t.hp = Math.min(t.maxHp, t.hp + amt);
          this.say(`${t.name} pulih ${amt} HP.`);
        }
        if (eff.also) {
          actor.statStages[eff.also.stat] = Math.min(6, actor.statStages[eff.also.stat] + eff.also.stages);
        }
        break;
      }
      case "aoe": {
        // Apex: kena seluruh party (selain target utama yang sudah kena di damage step? di sini full)
        this.party
          .filter((p) => p.hp > 0 && p !== target)
          .forEach((p) => {
            const { dmg } = calcDamage(actor, p, { category: "Special", power: 30, type: "Nature" });
            p.hp = Math.max(0, p.hp - dmg);
            if (p.hp <= 0) this.say(`${p.name} tumbang oleh gelombang!`);
          });
        this.say(`Gelombang ${actor.name} menyapu seluruh tim!`);
        break;
      }
    }
  };

  // ---- Aksi Seeker ----
  Battle.prototype.seekerAction = function (kind, target) {
    if (this.seekerCd > 0 && kind !== "bond") return false;
    const u = this.pending;
    this.pending = null;
    if (kind === "potion") {
      const t = target || this.alivePlayers().sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)[0];
      const amt = Math.round(t.maxHp * 0.45);
      t.hp = Math.min(t.maxHp, t.hp + amt);
      this.say(`🧪 Seeker memberi potion: ${t.name} pulih ${amt} HP.`);
      this.seekerCd = 2;
    } else if (kind === "scan") {
      this.say(`🔍 Seeker mengamati ${this.enemy.name}: ${hpBand(this.enemy.hp / this.enemy.maxHp).label}, tipe ${this.enemy.types.join("/")}.`);
      this.markCodexBonus(this.enemy.cid, 8, "Pindai medan");
      this.seekerCd = 1;
    } else if (kind === "bond") {
      return this.attemptBond();
    }
    this.afterAction();
    return true;
  };

  Battle.prototype.attemptBond = function () {
    if (this.isApex) {
      this.pending = this.pending || null;
      this.say(`✋ ${this.enemy.name} adalah Apex — ia tak bisa di-Bond, hanya dipahami lalu dilewati.`);
      this.afterAction();
      return false;
    }
    const rate = globalThis.Codex.bondRate(this.enemy.cid); // 0..100
    const roll = Math.random() * 100;
    this.say(`🤝 Attempt Bond ${this.enemy.name} — peluang ${rate}% (Codex).`);
    if (roll <= rate) {
      this.over = true;
      this.result = "bond";
      this.bondedInstance = this.enemy;
      this.say(`✨ BOND berhasil! ${this.enemy.name} kini berjalan bersamamu.`);
      return true;
    } else {
      this.say(`${this.enemy.name} belum cukup percaya... Bond gagal.`);
      this.afterAction();
      return false;
    }
  };

  // ---- AI musuh ----
  Battle.prototype.enemyTurn = function () {
    const e = this.enemy;
    if (e.hp <= 0) return;
    // target: unit dgn taunt, lalu HP terendah, lalu acak
    const players = this.alivePlayers();
    let target = players.find((p) => p.taunt > 0) || players.slice().sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)[0];
    // pilih move
    const skills = e.moves.slice(1); // semua skill non-basic
    let move = e.moves[0];
    if (skills.length) {
      if (this.isApex) {
        // Saat murka: utamakan serangan netral yang tak ter-resist (primal_crush); selain itu putar skill.
        const crush = skills.find((m) => m.id === "primal_crush");
        if (e.enraged && crush && Math.random() < 0.6) move = crush;
        else move = Math.random() < 0.85 ? skills[Math.floor(Math.random() * skills.length)] : e.moves[0];
      } else {
        move = Math.random() < 0.55 ? skills[0] : e.moves[0];
      }
    }
    this.useMove(e, move, target);
    this.tickBurn(e);
    this.checkEnd();
  };

  Battle.prototype.afterAction = function () {
    if (this.checkEnd()) return;
    this.advance();
  };

  // status tiap akhir aksi unit (burn) — diterapkan saat unit selesai bergerak
  Battle.prototype.tickBurn = function (u) {
    if (u.status === "burn" && u.hp > 0) {
      const d = Math.max(1, Math.round(u.maxHp * 0.06));
      u.hp = Math.max(0, u.hp - d);
      this.say(`${u.name} tersengat luka bakar (-${d}).`);
    }
  };

  Battle.prototype.checkEnd = function () {
    // burn tick di akhir setiap resolusi (sederhana: cek semua)
    if (this.enemy.hp <= 0) {
      this.over = true;
      this.result = "win";
      this.say(`🏆 ${this.enemy.name} dikalahkan!`);
      return true;
    }
    if (this.alivePlayers().length === 0) {
      this.over = true;
      this.result = "lose";
      this.say(`💤 Seluruh tim tumbang. Seeker mundur ke Hub.`);
      return true;
    }
    return false;
  };

  // ---- Codex observasi ----
  Battle.prototype.markObserved = function (cid, moveId) {
    this.observed[cid] = this.observed[cid] || {};
    if (!this.observed[cid][moveId]) {
      this.observed[cid][moveId] = true;
      const gained = globalThis.Codex.addFromSource(cid, "move_obs");
      if (gained > 0) {
        this.say(`📖 Codex ${this.enemy.name}: +${gained}% (melihat skill baru).`);
        this.bonus.codex.push({ cid, amt: gained });
      }
    }
  };
  Battle.prototype.markCodexBonus = function (cid, amt, why) {
    const g = globalThis.Codex.add(cid, amt);
    if (g > 0) this.say(`📖 Codex ${this.enemy.name}: +${g}% (${why}).`);
  };

  Battle.prototype.flee = function () {
    this.pending = null;
    let chance = 0.5 + 0.1 * this.alivePlayers().filter((p) => p.abilities.includes("soft_steps")).length;
    if (Math.random() < chance) {
      this.over = true;
      this.result = "flee";
      this.say("🏃 Berhasil melarikan diri.");
    } else {
      this.say("Gagal lari!");
      this.afterAction();
    }
  };

  globalThis.BattleEngine = { Battle, hpBand, effText, calcDamage };
})();
