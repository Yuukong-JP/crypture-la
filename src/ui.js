/* ui.js — lapisan presentasi vertical slice. Memanggil Game/Battle/Codex.
   Screen: intro -> hub -> zona (canvas) -> battle -> report -> codex. */
(function () {
  const $ = (s) => document.querySelector(s);
  const el = (h) => {
    const d = document.createElement("div");
    d.innerHTML = h.trim();
    return d.firstChild;
  };
  const C = DB.colors;
  function typeChip(t) {
    return `<span class="type" style="background:${C[t] || "#999"}">${t}</span>`;
  }
  function blob(inst) {
    const t = inst.types[0];
    return `<div class="blob" style="background:${C[t]}">${inst.name[0]}</div>`;
  }
  function speciesBlob(sp) {
    const t = sp.types[0];
    return `<div class="blob" style="background:${C[t]}">${sp.name[0]}</div>`;
  }

  function topbar() {
    const ri = Game.rankInfo(Game.rank);
    $("#t-rank").innerHTML = `Rank ${Game.rank} · ${ri.name}`;
    $("#t-gp").innerHTML = `GP <b>${Game.gp}</b>`;
    const nr = Game.nextRank();
    $("#t-gp").title = nr && !nr.placeholder ? `Menuju ${nr.name}: ${Game.gp}/${nr.gp_required} GP` : "Rank maks slice";
  }
  function setLoc(s) {
    $("#t-loc").textContent = s;
  }
  function screen(html) {
    $("#screen").innerHTML = "";
    $("#screen").appendChild(typeof html === "string" ? el(`<div>${html}</div>`) : html);
    topbar();
  }

  // ---------------- INTRO ----------------
  function intro() {
    setLoc("Prolog");
    screen(`
      <h2>Seorang Seeker, di tepi Verdwall</h2>
      <p class="lead">Kamu bukan pemburu. Kamu tak menangkap makhluk dengan melempar bola —
      kamu <b>memahami</b> mereka hingga mereka mau ber-<b>Bond</b> denganmu. Guild menyerahkan tiga sekutu pertamamu.
      Dunia tak terbentang otomatis; ia terbuka karena reputasimu naik.</p>
      <div class="grid" style="grid-template-columns:1fr 1fr 1fr">
        ${["001", "003", "005"].map((c) => {
          const sp = DB.SPECIES[c];
          return `<div class="card"><div class="unit">${speciesBlob(sp)}<div class="meta">
            <div class="name">${sp.name}</div>
            <div>${sp.types.map(typeChip).join(" ")}</div>
            <div class="role">peran: ${sp.role}</div></div></div>
            <div class="small" style="margin-top:8px">${sp.dex_entry}</div></div>`;
        }).join("")}
      </div>
      <p class="hint">Tiga starter di-Bond otomatis lewat story (Bagian 5). Codex mereka = 100%.</p>
      <div class="row" style="margin-top:14px"><button class="primary" id="go">Masuk ke Outpost Verdwall →</button></div>
    `);
    $("#go").onclick = hub;
  }

  // ---------------- HUB ----------------
  function hub() {
    setLoc("Outpost Verdwall (Hub)");
    const active = Game.activeMissions();
    const avail = Game.availableMissions();
    const wrap = el(`<div></div>`);
    wrap.innerHTML = `
      <h2>Outpost Verdwall</h2>
      <p class="lead">Hub para Seeker. Dari sini kamu memilih ekspedisi, menggali petunjuk Codex dari penduduk,
      lalu berangkat ke hutan. Pulang, lapor, dapat Guild Points, naik Rank.</p>
      <div class="grid" style="grid-template-columns:1fr 1fr">
        <div class="card">
          <h3>Tim Aktif (maks 3)</h3>
          <div id="party-mini"></div>
          <div class="row" style="margin-top:8px">
            <button id="b-team">Kelola Tim</button>
            <button id="b-codex">Buka Codex</button>
          </div>
        </div>
        <div class="card">
          <h3>Papan Ekspedisi</h3>
          <div id="missions"></div>
        </div>
      </div>
      <div class="card" style="margin-top:12px">
        <h3>Penduduk & Arsip Hub — sumber lore Codex</h3>
        <p class="small">Ngobrol & periksa buku mengisi Codex Crypture langka (Bagian 5: eksplorasi sosial = progres mekanis).</p>
        <div id="hub-int" class="row"></div>
      </div>
      <div class="row" style="margin-top:14px">
        <button class="primary" id="b-zone">⛺ Berangkat ke Hutan Luar Verdwall →</button>
      </div>
    `;
    // party mini
    const pm = wrap.querySelector("#party-mini");
    Game.party.forEach((p) => pm.appendChild(unitCard(p, false)));
    // missions
    const mm = wrap.querySelector("#missions");
    if (!active.length && !avail.length) mm.innerHTML = `<p class="small">Tidak ada kontrak tersedia.</p>`;
    active.forEach((m) => mm.appendChild(missionRow(m, "active")));
    avail.forEach((m) => mm.appendChild(missionRow(m, "available")));
    // hub interactions
    const hi = wrap.querySelector("#hub-int");
    DB.world.hub.interactions.forEach((it) => {
      const b = el(`<button>${it.kind === "book" ? "📖" : "💬"} ${it.name}</button>`);
      b.onclick = () => interact(it);
      hi.appendChild(b);
    });
    screen(wrap);
    wrap.querySelector("#b-zone").onclick = () => enterZone();
    wrap.querySelector("#b-codex").onclick = () => codexScreen(hub);
    wrap.querySelector("#b-team").onclick = () => teamScreen();
    wrap.querySelector("#b-zone").disabled = false;
  }

  function missionRow(m, state) {
    const tag = m.type === "story" ? "STORY" : "KONTRAK";
    const row = el(`<div class="card" style="margin-bottom:8px;background:#23392e">
      <div style="display:flex;align-items:center;gap:8px">
        <span class="tag">${tag}</span><b>${m.name}</b>
        <span class="spacer" style="flex:1"></span>
        <span class="tag">+${m.gp} GP</span>
      </div>
      <div class="small" style="margin-top:4px">${m.desc}</div>
    </div>`);
    if (state === "available") {
      const b = el(`<button style="margin-top:8px">Terima kontrak</button>`);
      b.onclick = () => {
        Game.acceptMission(m.id);
        hub();
      };
      row.appendChild(b);
    } else {
      row.appendChild(el(`<div class="small" style="margin-top:6px;color:#9ed27f">● Aktif — selesaikan di ekspedisi</div>`));
    }
    return row;
  }

  function interact(it) {
    const events = Codex.addLoreFromInteraction(it);
    let extra = events.length
      ? events.map((e) => `📖 Codex <b>${e.name}</b> +${e.amt}% — <span class="small">${e.detail}</span>`).join("<br>")
      : `<span class="small">(Tidak ada entri Codex baru dari sumber ini — mungkin sudah kamu catat.)</span>`;
    modal(`${it.kind === "book" ? "📖" : "💬"} ${it.name}`, `<p class="lead">“${it.text}”</p>${extra}`, hub);
  }

  function modal(title, body, onClose) {
    const m = el(`<div>
      <h2>${title}</h2>
      <div class="card">${body}</div>
      <div class="row" style="margin-top:14px"><button class="primary" id="mc">Kembali</button></div>
    </div>`);
    screen(m);
    m.querySelector("#mc").onclick = onClose;
  }

  // ---------------- UNIT CARD ----------------
  function unitCard(inst, hideHp) {
    const frac = inst.hp / inst.maxHp;
    const c = el(`<div class="card" style="margin-bottom:8px">
      <div class="unit">${blob(inst)}
        <div class="meta">
          <div class="name">${inst.name} <span class="small">Lv${inst.level}</span> ${inst.types.map(typeChip).join(" ")}</div>
          <div class="bar ${frac < 0.4 ? "low" : ""}"><i style="width:${Math.max(0, frac * 100)}%"></i></div>
          <div class="small">${hideHp ? "" : `HP ${Math.max(0, Math.round(inst.hp))}/${inst.maxHp}`} ${inst.status ? "· " + (inst.status === "burn" ? "🔥luka bakar" : inst.status) : ""}</div>
        </div>
      </div>
    </div>`);
    return c;
  }

  // ---------------- TEAM ----------------
  function teamScreen() {
    setLoc("Hub · Kelola Tim");
    const coll = Codex.State.bonded;
    const wrap = el(`<div><h2>Kelola Tim</h2>
      <p class="lead">Tim hanya bisa diatur di Hub, maksimal 3 (Bagian 7 LOCKED). Party = komitmen.</p>
      <h3>Tim Aktif</h3><div id="act" class="grid" style="grid-template-columns:1fr 1fr 1fr"></div>
      <h3 style="margin-top:12px">Koleksi (ter-Bond)</h3><div id="coll" class="grid" style="grid-template-columns:1fr 1fr 1fr"></div>
      <div class="row" style="margin-top:14px"><button class="primary" id="back">← Kembali ke Hub</button></div></div>`);
    function refresh() {
      const a = wrap.querySelector("#act");
      a.innerHTML = "";
      Game.party.forEach((p, i) => {
        const card = unitCard(p, false);
        const rm = el(`<button style="width:100%;margin-top:6px">Cadangkan</button>`);
        rm.disabled = Game.party.length <= 1;
        rm.onclick = () => {
          Game.party.splice(i, 1);
          refresh();
        };
        card.appendChild(rm);
        a.appendChild(card);
      });
      const cc = wrap.querySelector("#coll");
      cc.innerHTML = "";
      coll.forEach((inst) => {
        const inParty = Game.party.includes(inst);
        const card = unitCard(inst, false);
        const add = el(`<button style="width:100%;margin-top:6px">${inParty ? "Di tim" : "Masukkan tim"}</button>`);
        add.disabled = inParty || Game.party.length >= 3;
        add.onclick = () => {
          if (Game.party.length < 3) {
            inst.hp = inst.maxHp;
            Game.party.push(inst);
            refresh();
          }
        };
        card.appendChild(add);
        cc.appendChild(card);
      });
    }
    screen(wrap);
    refresh();
    wrap.querySelector("#back").onclick = hub;
  }

  // ---------------- CODEX ----------------
  function codexScreen(back) {
    setLoc("Codex");
    const wrap = el(`<div><h2>Codex — Field Guide</h2>
      <p class="lead">Isi Codex sebuah Crypture sampai 100% = Bond dijamin (Bagian 5, hook utama).
      Sumber tersebar di dunia: encounter, observasi skill, habitat, dan lore (NPC/buku).</p>
      <div id="list"></div>
      <div class="row" style="margin-top:14px"><button class="primary" id="back">← Kembali</button></div></div>`);
    const list = wrap.querySelector("#list");
    DB.raw.crypture.crypture.forEach((sp) => {
      const pct = Codex.get(sp.id);
      if (pct <= 0 && !Codex.isBonded(sp.id) && sp.rarity !== "Starter") {
        // belum ketemu: tampil samar
        list.appendChild(el(`<div class="card" style="margin-bottom:8px;opacity:.5">
          <div class="unit"><div class="blob" style="background:#33513f">?</div>
          <div class="meta"><div class="name">#${sp.id} · ???</div><div class="small">Belum terdokumentasi</div></div></div></div>`));
        return;
      }
      const bonded = Codex.isBonded(sp.id);
      const card = el(`<div class="card" style="margin-bottom:8px">
        <div class="unit">${speciesBlob(sp)}
          <div class="meta">
            <div class="name">#${sp.id} · ${sp.name} ${sp.types.map(typeChip).join(" ")}
              ${bonded ? '<span class="tag" style="color:#9ed27f">BONDED</span>' : ""}
              ${!sp.bondable ? '<span class="tag" style="color:#eaa05f">APEX · no bond</span>' : ""}</div>
            <div class="bar codex"><i style="width:${pct}%"></i></div>
            <div class="small">Codex ${pct}% · peran ${sp.role} · ${sp.rarity}</div>
          </div></div>
        <div class="small" style="margin-top:8px">${sp.dex_entry}</div>
        <div style="margin-top:6px">${sources(sp)}</div>
      </div>`);
      list.appendChild(card);
    });
    screen(wrap);
    wrap.querySelector("#back").onclick = back || hub;
  }
  function sources(sp) {
    const used = Codex.State.sourcesUsed[sp.id] || {};
    return (sp.info_sources || [])
      .map((s) => {
        const done = used[s.detail];
        return `<div class="src ${done ? "done" : ""}">${done ? "✔" : "○"} [${s.source_type}] ${s.detail} <span style="opacity:.7">(+${s.codex_gain}%)</span></div>`;
      })
      .join("");
  }

  // ---------------- ZONE (eksplorasi canvas) ----------------
  const TILE = 48;
  let zone = null;
  function enterZone() {
    setLoc("Hutan Luar Verdwall");
    const Z = DB.world.zone;
    zone = {
      data: Z,
      player: { x: 7, y: 9 },
      creatures: Z.spawns.map((s) => ({ ...s, alive: true })),
      lore: Z.lore_points.map((l) => ({ ...l, used: false })),
      msg: "Gunakan WASD / panah untuk bergerak. Dekati Crypture untuk encounter. Capai pintu keluar untuk pulang.",
    };
    const wrap = el(`<div>
      <h2>Hutan Luar Verdwall</h2>
      <canvas id="zc" width="${Z.size.w * TILE}" height="${Z.size.h * TILE}"></canvas>
      <p class="small" id="zmsg" style="margin-top:8px"></p>
      <div class="row"><button id="leave">↩ Paksa pulang ke Hub</button>
      <span class="hint">Crypture liar lebih kuat dari versi ter-Bond (wild_multiplier).</span></div>
    </div>`);
    screen(wrap);
    wrap.querySelector("#leave").onclick = () => endExpedition("Kamu memilih pulang.");
    drawZone();
    bindKeys();
  }

  function bindKeys() {
    document.onkeydown = (e) => {
      if (!zone) return;
      let dx = 0,
        dy = 0;
      const k = e.key.toLowerCase();
      if (k === "arrowup" || k === "w") dy = -1;
      else if (k === "arrowdown" || k === "s") dy = 1;
      else if (k === "arrowleft" || k === "a") dx = -1;
      else if (k === "arrowright" || k === "d") dx = 1;
      else return;
      e.preventDefault();
      movePlayer(dx, dy);
    };
  }

  function movePlayer(dx, dy) {
    const Z = zone.data;
    const nx = Math.max(0, Math.min(Z.size.w - 1, zone.player.x + dx));
    const ny = Math.max(0, Math.min(Z.size.h - 1, zone.player.y + dy));
    zone.player.x = nx;
    zone.player.y = ny;
    // wild behavior: flee creature steps away occasionally
    zone.creatures.forEach((c) => {
      if (!c.alive) return;
      if (c.behavior === "flee" && Math.abs(c.x - nx) + Math.abs(c.y - ny) <= 3 && Math.random() < 0.6) {
        c.x = Math.max(0, Math.min(Z.size.w - 1, c.x + (c.x < nx ? -1 : 1)));
      } else if (c.behavior === "wander" && Math.random() < 0.3) {
        c.x = Math.max(0, Math.min(Z.size.w - 1, c.x + (Math.random() < 0.5 ? -1 : 1)));
      }
    });
    // exit?
    if (nx === Z.exit.x && ny === Z.exit.y) return endExpedition("Kamu kembali ke Hub melalui jalur keluar.");
    // lore point?
    const lp = zone.lore.find((l) => !l.used && l.x === nx && l.y === ny);
    if (lp) {
      lp.used = true;
      const g = Codex.addFromSource(lp.for, lp.source_type, undefined);
      const sp = DB.SPECIES[lp.for];
      zone.msg = `🌿 ${lp.name}: ${lp.text} ${g > 0 ? `Codex ${sp.name} +${g}%.` : ""}`;
    }
    // adjacent creature -> encounter
    const enc = zone.creatures.find((c) => c.alive && Math.abs(c.x - nx) + Math.abs(c.y - ny) === 0);
    if (enc) {
      startEncounter(enc);
      return;
    }
    drawZone();
  }

  function drawZone() {
    const Z = zone.data;
    const cv = $("#zc");
    if (!cv) return;
    const g = cv.getContext("2d");
    // ground
    for (let y = 0; y < Z.size.h; y++)
      for (let x = 0; x < Z.size.w; x++) {
        g.fillStyle = (x + y) % 2 ? "#274a2f" : "#244328";
        g.fillRect(x * TILE, y * TILE, TILE, TILE);
      }
    // scattered trees (decor, deterministic)
    g.globalAlpha = 0.5;
    for (let i = 0; i < 26; i++) {
      const x = (i * 7) % Z.size.w,
        y = (i * 5 + 2) % Z.size.h;
      if ((x === Z.exit.x && y === Z.exit.y)) continue;
      g.font = "26px serif";
      g.fillText("🌲", x * TILE + 8, y * TILE + 34);
    }
    g.globalAlpha = 1;
    // exit
    g.font = "30px serif";
    g.fillText("🚪", Z.exit.x * TILE + 8, Z.exit.y * TILE + 36);
    // lore points
    zone.lore.forEach((l) => {
      if (l.used) return;
      g.font = "24px serif";
      g.fillText("✨", l.x * TILE + 12, l.y * TILE + 34);
    });
    // creatures
    zone.creatures.forEach((c) => {
      if (!c.alive) return;
      const sp = DB.SPECIES[c.cid];
      g.fillStyle = C[sp.types[0]];
      g.beginPath();
      g.arc(c.x * TILE + TILE / 2, c.y * TILE + TILE / 2, 15, 0, 7);
      g.fill();
      g.fillStyle = "#11201a";
      g.font = "bold 16px sans-serif";
      g.textAlign = "center";
      g.fillText(sp.name[0], c.x * TILE + TILE / 2, c.y * TILE + TILE / 2 + 6);
      g.textAlign = "left";
    });
    // player
    const p = zone.player;
    g.font = "30px serif";
    g.fillText("🧭", p.x * TILE + 8, p.y * TILE + 36);
    const m = $("#zmsg");
    if (m) m.textContent = zone.msg;
  }

  function startEncounter(spawn) {
    const sp = DB.SPECIES[spawn.cid];
    const isApex = !sp.bondable;
    const enemy = DB.makeInstance(spawn.cid, spawn.level, !isApex);
    // encounter source codex
    const g = Codex.addFromSource(spawn.cid, "encounter");
    document.onkeydown = null;
    startBattle(enemy, () => {
      // setelah battle, kembali ke zona jika menang/lari, ke report jika kalah/bond
    }, spawn);
  }

  // ---------------- BATTLE ----------------
  let B = null;
  let battleDone = null;
  let battleSpawn = null;
  function startBattle(enemy, onDone, spawn) {
    battleSpawn = spawn;
    // pastikan party fresh? tidak — bawa kondisi HP saat ini
    B = new BattleEngine.Battle(Game.party, enemy);
    battleDone = onDone;
    renderBattle();
  }

  function renderBattle() {
    setLoc("Pertarungan");
    const enemy = B.enemy;
    const band = BattleEngine.hpBand(enemy.hp / enemy.maxHp);
    const wrap = el(`<div>
      <h2>Pertarungan — ${enemy.name}${B.isApex ? " <span class='tag' style='color:#eaa05f'>APEX</span>" : " <span class='tag'>liar</span>"}</h2>
      <div class="grid" style="grid-template-columns:1.1fr .9fr;align-items:start">
        <div>
          <h3>Lawan (HP tersembunyi)</h3>
          <div class="card">
            <div class="unit">${blob(enemy)}<div class="meta">
              <div class="name">${enemy.name} <span class="small">Lv${enemy.level}</span> ${enemy.types.map(typeChip).join(" ")} ${enemy.enraged ? "<span class='tag' style='color:#e0683b'>🌑 MURKA</span>" : ""}</div>
              <div class="bar ${enemy.hp / enemy.maxHp < 0.4 ? "low" : ""}"><i style="width:${(enemy.hp / enemy.maxHp) * 100}%"></i></div>
              <div class="small">Kondisi: <span class="band ${band.cls}">${band.label}</span> ${enemy.status ? "· 🔥" : ""}
              ${B.isApex ? "" : `· Codex ${Codex.get(enemy.cid)}% → Bond ${Codex.bondRate(enemy.cid)}%`}</div>
            </div></div>
            <div class="small" style="margin-top:6px">${enemy.species.dex_entry}</div>
          </div>
          <h3 style="margin-top:10px">Tim Seeker</h3>
          <div id="party"></div>
        </div>
        <div>
          <h3>Perintah</h3>
          <div id="cmd"></div>
          <h3 style="margin-top:10px">Catatan Pertempuran</h3>
          <div id="log"></div>
        </div>
      </div>
    </div>`);
    const pc = wrap.querySelector("#party");
    Game.party.forEach((p) => {
      const card = unitCard(p, false);
      if (B.pending === p) card.style.outline = "2px solid var(--gold)";
      if (p.hp <= 0) card.style.opacity = ".45";
      pc.appendChild(card);
    });
    screen(wrap);
    renderLog();
    renderCmd();
  }

  function renderLog() {
    const lg = $("#log");
    if (!lg) return;
    lg.innerHTML = B.log.map((l) => `<div>${l}</div>`).join("");
    lg.scrollTop = lg.scrollHeight;
  }

  function renderCmd() {
    const cmd = $("#cmd");
    if (!cmd) return;
    if (B.over) {
      cmd.innerHTML = "";
      const b = el(`<button class="primary" style="width:100%">Lanjut →</button>`);
      b.onclick = () => resolveBattle();
      cmd.appendChild(b);
      return;
    }
    const u = B.pending;
    if (!u) {
      cmd.innerHTML = `<p class="small">…</p>`;
      setTimeout(() => {
        renderBattle();
      }, 250);
      return;
    }
    cmd.innerHTML = `<div class="small" style="margin-bottom:6px">Giliran: <b>${u.name}</b> (${u.role})</div>`;
    const menu = el(`<div class="menu"></div>`);
    // skills
    u.moves.forEach((mv) => {
      const dmgHint = mv.power > 0 ? "" : "·status";
      const tip = mv.type !== "Normal" ? typeChip(mv.type) : `<span class="type" style="background:#c9c2b2">basic</span>`;
      const b = el(`<button title="${mv.desc}">${mv.name} ${tip}</button>`);
      b.onclick = () => {
        B.playerMove(mv);
        afterPlayer();
      };
      menu.appendChild(b);
    });
    // seeker actions
    const pot = el(`<button class="warm" ${B.seekerCd > 0 ? "disabled" : ""}>🧪 Potion${B.seekerCd > 0 ? ` (cd ${B.seekerCd})` : ""}</button>`);
    pot.onclick = () => {
      B.seekerAction("potion");
      afterPlayer();
    };
    menu.appendChild(pot);
    const scan = el(`<button ${B.seekerCd > 0 ? "disabled" : ""}>🔍 Scan</button>`);
    scan.onclick = () => {
      B.seekerAction("scan");
      afterPlayer();
    };
    menu.appendChild(scan);
    if (!B.isApex) {
      const bond = el(`<button class="primary">🤝 Attempt Bond (${Codex.bondRate(B.enemy.cid)}%)</button>`);
      bond.onclick = () => {
        B.seekerAction("bond");
        afterPlayer();
      };
      menu.appendChild(bond);
    }
    const flee = el(`<button>🏃 Lari</button>`);
    flee.onclick = () => {
      B.flee();
      afterPlayer();
    };
    menu.appendChild(flee);
    cmd.appendChild(menu);
    const hint = el(`<p class="hint">Aksi Seeker punya cooldown — bukan tombol menang. Tank menahan, support menyembuhkan, attacker memukul: nilai ada di kombinasi tim.</p>`);
    cmd.appendChild(hint);
  }

  function afterPlayer() {
    renderBattle();
  }

  function resolveBattle() {
    const events = Game.onBattleResult(B);
    // tandai creature di zona
    if (battleSpawn && (B.result === "win" || B.result === "bond")) {
      const c = zone && zone.creatures.find((x) => x === battleSpawn || (x.cid === battleSpawn.cid && x.x === battleSpawn.x && x.y === battleSpawn.y));
      if (c) c.alive = false;
    }
    const res = B.result;
    const enemyName = B.enemy.name;
    const bonusEvents = events;
    if (res === "lose") return endExpedition("Tim tumbang — kamu dipulihkan di Hub.", bonusEvents);
    // setelah menang/bond/lari: jika ini Apex (story klimaks) -> report; else kembali ke zona
    if (B.isApex && res === "win") {
      return apexVictory(bonusEvents);
    }
    // tampilkan ringkasan kecil lalu kembali ke zona
    const wrap = el(`<div><h2>${res === "bond" ? "✨ Bond Berhasil" : res === "flee" ? "Lolos" : "Menang"}</h2>
      <div class="card"><div class="small">${B.log.slice(-6).join("<br>")}</div></div>
      ${bonusEvents.length ? `<div class="card" style="margin-top:8px">${bonusEvents.map((e) => "✅ " + e).join("<br>")}</div>` : ""}
      <div class="row" style="margin-top:12px">
        <button class="primary" id="cont">↩ Lanjut menjelajah</button>
        <button id="home">Pulang ke Hub</button>
      </div></div>`);
    screen(wrap);
    wrap.querySelector("#cont").onclick = () => {
      setLoc("Hutan Luar Verdwall");
      const w = el(`<div><h2>Hutan Luar Verdwall</h2>
        <canvas id="zc" width="${zone.data.size.w * TILE}" height="${zone.data.size.h * TILE}"></canvas>
        <p class="small" id="zmsg"></p>
        <div class="row"><button id="leave">↩ Paksa pulang ke Hub</button></div></div>`);
      screen(w);
      w.querySelector("#leave").onclick = () => endExpedition("Kamu memilih pulang.");
      zone.msg = res === "bond" ? `${enemyName} kini bagian dari timmu.` : `${enemyName} telah ditangani.`;
      drawZone();
      bindKeys();
    };
    wrap.querySelector("#home").onclick = () => endExpedition("Kamu kembali ke Hub.");
  }

  function apexVictory(bonusEvents) {
    document.onkeydown = null;
    zone = null;
    setLoc("Jantung Verdwall");
    screen(`<div><h2>🌳 Jantung Verdwall — Story Thread Tertutup</h2>
      <p class="lead">Eldergrove tidak tumbang seperti makhluk biasa. Ia melambat, mengakui kehadiranmu,
      lalu surut ke akar dunia. Kamu tak menangkapnya — kamu <b>memahaminya, lalu melewatinya</b>.
      Di kejauhan, nama <i>Luvirel</i> dan <i>Merlyon</i> berbisik: Verdwall hanyalah satu daun dari pohon yang jauh lebih besar.</p>
      <div class="card">${bonusEvents.map((e) => "✅ " + e).join("<br>") || "Verdwall ditaklukkan."}</div>
      <p class="hint">Avalon terbuka setelah seluruh region ditaklukkan — endgame di luar slice ini.</p>
      <div class="row" style="margin-top:14px"><button class="primary" id="back">← Kembali ke Hub</button></div></div>`);
    $("#back").onclick = hub;
  }

  function endExpedition(note, extraEvents) {
    document.onkeydown = null;
    zone = null;
    // pulihkan tim di hub
    Game.party.forEach((p) => {
      p.hp = p.maxHp;
      p.status = null;
      p.statStages = { atk: 0, def: 0, sp_atk: 0, sp_def: 0, speed: 0 };
      p.enraged = false;
      p.taunt = 0;
    });
    setLoc("Outpost Verdwall (Hub)");
    screen(`<div><h2>Lapor ke Guild</h2>
      <p class="lead">${note}</p>
      <div class="card">
        <div class="small">Rank ${Game.rank} · ${Game.rankInfo(Game.rank).name} — GP ${Game.gp}${
          Game.nextRank() && !Game.nextRank().placeholder ? ` / ${Game.nextRank().gp_required} menuju ${Game.nextRank().name}` : ""
        }</div>
      </div>
      ${extraEvents && extraEvents.length ? `<div class="card" style="margin-top:8px">${extraEvents.map((e) => "✅ " + e).join("<br>")}</div>` : ""}
      <div class="row" style="margin-top:14px"><button class="primary" id="ok">Masuk Hub →</button></div></div>`);
    $("#ok").onclick = hub;
  }

  function boot() {
    Game.init();
    intro();
  }

  globalThis.UI = { boot, hub, intro };
})();
