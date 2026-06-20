window.GAME_DATA = {
  "types": {
    "_note": "14x14 dirancang; slice memakai 10 tipe inti Gen 1. Hanya entri non-1.0 yang ditulis; loader mengisi sisanya 1.0. Angka = balance pass nanti (struktur yang dikunci, bukan nilai).",
    "types": [
      "Nature",
      "Ember",
      "Tide",
      "Terra",
      "Gale",
      "Void",
      "Lumen",
      "Crystal",
      "Alloy",
      "Feral"
    ],
    "colors": {
      "Nature": "#6fae57",
      "Ember": "#e0683b",
      "Tide": "#3f8fd0",
      "Terra": "#b08b53",
      "Gale": "#8fcfc4",
      "Void": "#5a4a78",
      "Lumen": "#e7c659",
      "Crystal": "#9ec9e0",
      "Alloy": "#9aa3ad",
      "Feral": "#a4504f",
      "Normal": "#c9c2b2"
    },
    "chart": {
      "Nature": {
        "Tide": 2.0,
        "Terra": 2.0,
        "Ember": 0.5,
        "Nature": 0.5,
        "Gale": 0.5
      },
      "Ember": {
        "Nature": 2.0,
        "Crystal": 2.0,
        "Alloy": 2.0,
        "Tide": 0.5,
        "Ember": 0.5,
        "Terra": 0.5
      },
      "Tide": {
        "Ember": 2.0,
        "Terra": 2.0,
        "Nature": 0.5,
        "Tide": 0.5
      },
      "Terra": {
        "Ember": 2.0,
        "Crystal": 2.0,
        "Alloy": 2.0,
        "Nature": 0.5,
        "Gale": 0.0
      },
      "Gale": {
        "Nature": 2.0,
        "Feral": 2.0,
        "Terra": 0.5,
        "Crystal": 0.5
      },
      "Void": {
        "Lumen": 2.0,
        "Void": 2.0,
        "Feral": 0.5
      },
      "Lumen": {
        "Void": 2.0,
        "Feral": 2.0,
        "Lumen": 0.5
      },
      "Crystal": {
        "Gale": 2.0,
        "Tide": 2.0,
        "Ember": 0.5,
        "Terra": 0.5
      },
      "Alloy": {
        "Crystal": 2.0,
        "Nature": 2.0,
        "Ember": 0.5,
        "Alloy": 0.5
      },
      "Feral": {
        "Void": 2.0,
        "Lumen": 2.0,
        "Gale": 0.5
      }
    }
  },
  "moves": {
    "_note": "Skema Move = Data Spec 8.2. Basic attack selalu tersedia (lantai damage). 'Move' = skill role-defining. power/accuracy = provisional, balance pass nanti.",
    "moves": {
      "basic_strike": {
        "id": "basic_strike",
        "name": "Basic Strike",
        "type": "Normal",
        "category": "Physical",
        "power": 18,
        "accuracy": 100,
        "cost": 0,
        "effect": null,
        "desc": "Serangan dasar yang selalu tersedia bagi tiap Crypture."
      },
      "bramble_wall": {
        "id": "bramble_wall",
        "name": "Bramble Wall",
        "type": "Nature",
        "category": "Status",
        "power": 0,
        "accuracy": 100,
        "cost": 2,
        "effect": {
          "kind": "buff",
          "stat": "def",
          "stages": 2,
          "target": "self",
          "taunt": 2
        },
        "desc": "Mendirikan dinding duri: Def naik tajam & memaksa musuh menyerang dirinya (taunt)."
      },
      "ember_fang": {
        "id": "ember_fang",
        "name": "Ember Fang",
        "type": "Ember",
        "category": "Physical",
        "power": 45,
        "accuracy": 95,
        "cost": 2,
        "effect": {
          "kind": "status",
          "status": "burn",
          "chance": 0.3
        },
        "desc": "Gigitan membara; berpeluang membakar lawan."
      },
      "tide_mend": {
        "id": "tide_mend",
        "name": "Tide Mend",
        "type": "Tide",
        "category": "Status",
        "power": 0,
        "accuracy": 100,
        "cost": 2,
        "effect": {
          "kind": "heal",
          "amount": 0.35,
          "target": "ally_lowest",
          "also": {
            "stat": "sp_def",
            "stages": 1,
            "target": "self"
          }
        },
        "desc": "Mengalirkan air penyembuh ke rekan paling terluka; Sp.Def diri naik."
      },
      "spore_drift": {
        "id": "spore_drift",
        "name": "Spore Drift",
        "type": "Nature",
        "category": "Status",
        "power": 0,
        "accuracy": 90,
        "cost": 2,
        "effect": {
          "kind": "debuff",
          "stat": "atk",
          "stages": 1,
          "target": "enemy"
        },
        "desc": "Menyebar spora yang menumpulkan serangan lawan (Atk turun)."
      },
      "glare_pulse": {
        "id": "glare_pulse",
        "name": "Glare Pulse",
        "type": "Lumen",
        "category": "Special",
        "power": 40,
        "accuracy": 100,
        "cost": 2,
        "effect": null,
        "desc": "Denyut cahaya menyilaukan."
      },
      "rock_lob": {
        "id": "rock_lob",
        "name": "Rock Lob",
        "type": "Terra",
        "category": "Physical",
        "power": 42,
        "accuracy": 90,
        "cost": 2,
        "effect": null,
        "desc": "Melempar bongkahan batu berat."
      },
      "gust_slash": {
        "id": "gust_slash",
        "name": "Gust Slash",
        "type": "Gale",
        "category": "Physical",
        "power": 38,
        "accuracy": 95,
        "cost": 2,
        "effect": {
          "kind": "debuff",
          "stat": "speed",
          "stages": 1,
          "target": "enemy"
        },
        "desc": "Sabetan angin tajam yang memperlambat lawan."
      },
      "bubble_veil": {
        "id": "bubble_veil",
        "name": "Bubble Veil",
        "type": "Tide",
        "category": "Status",
        "power": 0,
        "accuracy": 100,
        "cost": 2,
        "effect": {
          "kind": "buff",
          "stat": "sp_def",
          "stages": 2,
          "target": "self"
        },
        "desc": "Selubung gelembung menebalkan pertahanan khusus."
      },
      "verdant_judgement": {
        "id": "verdant_judgement",
        "name": "Verdant Judgement",
        "type": "Nature",
        "category": "Special",
        "power": 72,
        "accuracy": 100,
        "cost": 3,
        "effect": {
          "kind": "aoe"
        },
        "desc": "Vonis hutan menghantam SELURUH tim Seeker sekaligus."
      },
      "primal_crush": {
        "id": "primal_crush",
        "name": "Primal Crush",
        "type": "Normal",
        "category": "Physical",
        "power": 52,
        "accuracy": 100,
        "cost": 3,
        "effect": null,
        "desc": "Hantaman murni tanpa elemen — menembus tim yang mengandalkan resistansi tipe."
      },
      "deep_roots": {
        "id": "deep_roots",
        "name": "Deep Roots",
        "type": "Nature",
        "category": "Status",
        "power": 0,
        "accuracy": 100,
        "cost": 3,
        "effect": {
          "kind": "heal",
          "amount": 0.18,
          "target": "self"
        },
        "desc": "Akar purba menyerap kehidupan tanah; Eldergrove memulihkan diri."
      }
    }
  },
  "crypture": {
    "_note": "Skema = Data Spec 8.1. base_stats di sini PROVISIONAL agar slice bisa dimainkan (dokumen menaruh 0 utk diisi balance pass). Struktur & info_sources final sebagai pola. Tambah Crypture = tambah 1 entri, tanpa sentuh kode.",
    "crypture": [
      {
        "id": "001",
        "name": "Verduck",
        "types": [
          "Nature"
        ],
        "class": "Guardian",
        "role": "tank",
        "rarity": "Starter",
        "bondable": true,
        "base_stats": {
          "hp": 32,
          "atk": 9,
          "def": 12,
          "sp_atk": 8,
          "sp_def": 11,
          "speed": 7
        },
        "growth_curve": {
          "hp": 6,
          "atk": 1,
          "def": 3,
          "sp_atk": 1,
          "sp_def": 2,
          "speed": 1
        },
        "abilities": [
          {
            "id": "bark_skin",
            "name": "Bark Skin",
            "unlock_level": 1,
            "desc": "Menerima 15% lebih sedikit damage."
          },
          {
            "id": "rooted",
            "name": "Rooted",
            "unlock_level": 10,
            "desc": "Kebal terhadap penurunan Speed."
          }
        ],
        "natural_skill": {
          "move": "bramble_wall",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "bubble_veil",
          "spore_drift"
        ],
        "evolution": {
          "trigger": "level",
          "value": 18,
          "target": "002"
        },
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.0,
        "info_sources": [
          {
            "source_type": "lore",
            "detail": "Diberikan oleh Guild saat intro (auto-Bond)",
            "location": "hub",
            "codex_gain": 100
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Penjaga rawa berdarah dingin yang memilih bertahan ketimbang menyerang. Cangkang lumutnya menebal tiap musim."
      },
      {
        "id": "003",
        "name": "Pyruff",
        "types": [
          "Ember"
        ],
        "class": "Wanderer",
        "role": "attacker",
        "rarity": "Starter",
        "bondable": true,
        "base_stats": {
          "hp": 24,
          "atk": 13,
          "def": 7,
          "sp_atk": 11,
          "sp_def": 7,
          "speed": 11
        },
        "growth_curve": {
          "hp": 4,
          "atk": 4,
          "def": 1,
          "sp_atk": 2,
          "sp_def": 1,
          "speed": 2
        },
        "abilities": [
          {
            "id": "kindling",
            "name": "Kindling",
            "unlock_level": 1,
            "desc": "Atk +30% saat HP di bawah sepertiga."
          },
          {
            "id": "scorch",
            "name": "Scorch",
            "unlock_level": 8,
            "desc": "Basic attack berpeluang membakar."
          }
        ],
        "natural_skill": {
          "move": "ember_fang",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "gust_slash"
        ],
        "evolution": {
          "trigger": "level",
          "value": 18,
          "target": "004"
        },
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.0,
        "info_sources": [
          {
            "source_type": "lore",
            "detail": "Diberikan oleh Guild saat intro (auto-Bond)",
            "location": "hub",
            "codex_gain": 100
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Anak api berbulu yang tak bisa diam. Ekornya menyala lebih terang saat ia terdesak — bukti nyali, kata para Seeker."
      },
      {
        "id": "005",
        "name": "Ripplet",
        "types": [
          "Tide"
        ],
        "class": "Mystic",
        "role": "support",
        "rarity": "Starter",
        "bondable": true,
        "base_stats": {
          "hp": 27,
          "atk": 8,
          "def": 9,
          "sp_atk": 12,
          "sp_def": 12,
          "speed": 9
        },
        "growth_curve": {
          "hp": 5,
          "atk": 1,
          "def": 2,
          "sp_atk": 3,
          "sp_def": 3,
          "speed": 1
        },
        "abilities": [
          {
            "id": "tidecaller",
            "name": "Tidecaller",
            "unlock_level": 1,
            "desc": "Efek penyembuhan +15%."
          },
          {
            "id": "undertow",
            "name": "Undertow",
            "unlock_level": 10,
            "desc": "Skill Tide menurunkan Speed musuh."
          }
        ],
        "natural_skill": {
          "move": "tide_mend",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "bubble_veil"
        ],
        "evolution": {
          "trigger": "level",
          "value": 18,
          "target": "006"
        },
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.0,
        "info_sources": [
          {
            "source_type": "lore",
            "detail": "Diberikan oleh Guild saat intro (auto-Bond)",
            "location": "hub",
            "codex_gain": 100
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Roh kolam yang tenang. Dikatakan Ripplet menyembuhkan luka yang bahkan tak terlihat oleh pemiliknya."
      },
      {
        "id": "010",
        "name": "Cappin",
        "types": [
          "Nature"
        ],
        "class": "Wanderer",
        "role": "support",
        "rarity": "Common",
        "bondable": true,
        "base_stats": {
          "hp": 26,
          "atk": 9,
          "def": 9,
          "sp_atk": 9,
          "sp_def": 9,
          "speed": 9
        },
        "growth_curve": {
          "hp": 4,
          "atk": 2,
          "def": 2,
          "sp_atk": 2,
          "sp_def": 2,
          "speed": 2
        },
        "abilities": [
          {
            "id": "soft_steps",
            "name": "Soft Steps",
            "unlock_level": 1,
            "desc": "Lebih mungkin lolos saat Lari."
          },
          {
            "id": "spore_cloud",
            "name": "Spore Cloud",
            "unlock_level": 9,
            "desc": "Spore Drift kadang juga menidurkan."
          }
        ],
        "natural_skill": {
          "move": "spore_drift",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "bubble_veil"
        ],
        "evolution": {
          "trigger": "level",
          "value": 20,
          "target": "gloowaddle"
        },
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.25,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di hutan luar",
            "location": "verdwall_forest_outer",
            "codex_gain": 20
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memakai Spore Drift",
            "location": "battle",
            "codex_gain": 15
          },
          {
            "source_type": "habitat",
            "detail": "Amati ia merumput di bawah pohon tua",
            "location": "verdwall_forest_outer",
            "codex_gain": 15
          },
          {
            "source_type": "lore",
            "detail": "NPC: Tetua Desa Verdwall",
            "location": "hub",
            "codex_gain": 25
          },
          {
            "source_type": "lore",
            "detail": "Buku: Catatan Hutan",
            "location": "hub",
            "codex_gain": 25
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Crypture pertama yang berani mendekati manusia. Topi sporanya mengembang saat ia merasa aman."
      },
      {
        "id": "011",
        "name": "Glimmoth",
        "types": [
          "Lumen"
        ],
        "class": "Mystic",
        "role": "attacker",
        "rarity": "Common",
        "bondable": true,
        "base_stats": {
          "hp": 22,
          "atk": 7,
          "def": 7,
          "sp_atk": 12,
          "sp_def": 9,
          "speed": 12
        },
        "growth_curve": {
          "hp": 4,
          "atk": 1,
          "def": 1,
          "sp_atk": 3,
          "sp_def": 2,
          "speed": 3
        },
        "abilities": [
          {
            "id": "dust_glow",
            "name": "Dust Glow",
            "unlock_level": 1,
            "desc": "Skill Lumen sedikit lebih kuat."
          },
          {
            "id": "flutter",
            "name": "Flutter",
            "unlock_level": 9,
            "desc": "Speed +1 di awal battle."
          }
        ],
        "natural_skill": {
          "move": "glare_pulse",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.25,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di rumpun bercahaya",
            "location": "verdwall_forest_outer",
            "codex_gain": 25
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memakai Glare Pulse",
            "location": "battle",
            "codex_gain": 20
          },
          {
            "source_type": "lore",
            "detail": "Buku: Catatan Hutan",
            "location": "hub",
            "codex_gain": 25
          },
          {
            "source_type": "lore",
            "detail": "NPC: Penjaga Lentera",
            "location": "hub",
            "codex_gain": 30
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Ngengat cahaya yang hanya muncul di rumpun jamur berpendar. Tepung sayapnya konon memandu Seeker yang tersesat."
      },
      {
        "id": "012",
        "name": "Pebblion",
        "types": [
          "Terra"
        ],
        "class": "Guardian",
        "role": "tank",
        "rarity": "Common",
        "bondable": true,
        "base_stats": {
          "hp": 30,
          "atk": 11,
          "def": 13,
          "sp_atk": 6,
          "sp_def": 8,
          "speed": 5
        },
        "growth_curve": {
          "hp": 6,
          "atk": 2,
          "def": 3,
          "sp_atk": 1,
          "sp_def": 1,
          "speed": 1
        },
        "abilities": [
          {
            "id": "sturdy_hide",
            "name": "Sturdy Hide",
            "unlock_level": 1,
            "desc": "Menerima 10% lebih sedikit damage fisik."
          },
          {
            "id": "tremor",
            "name": "Tremor",
            "unlock_level": 11,
            "desc": "Rock Lob kadang menurunkan Def musuh."
          }
        ],
        "natural_skill": {
          "move": "rock_lob",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "spore_drift"
        ],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.3,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di tepian berbatu",
            "location": "verdwall_forest_outer",
            "codex_gain": 25
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memakai Rock Lob",
            "location": "battle",
            "codex_gain": 20
          },
          {
            "source_type": "habitat",
            "detail": "Amati ia tidur menyamar jadi batu",
            "location": "verdwall_forest_outer",
            "codex_gain": 20
          },
          {
            "source_type": "lore",
            "detail": "NPC: Tukang Batu Hub",
            "location": "hub",
            "codex_gain": 35
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Bongkahan hidup yang tidur berabad-abad. Yang sabar menunggu konon akan disambut sebagai sekutu paling setia."
      },
      {
        "id": "013",
        "name": "Gustling",
        "types": [
          "Gale"
        ],
        "class": "Wanderer",
        "role": "attacker",
        "rarity": "Common",
        "bondable": true,
        "base_stats": {
          "hp": 23,
          "atk": 12,
          "def": 7,
          "sp_atk": 8,
          "sp_def": 7,
          "speed": 14
        },
        "growth_curve": {
          "hp": 4,
          "atk": 3,
          "def": 1,
          "sp_atk": 1,
          "sp_def": 1,
          "speed": 3
        },
        "abilities": [
          {
            "id": "tailwind",
            "name": "Tailwind",
            "unlock_level": 1,
            "desc": "Sering bergerak lebih dulu."
          },
          {
            "id": "evasive",
            "name": "Evasive",
            "unlock_level": 10,
            "desc": "Kadang mengelak serangan."
          }
        ],
        "natural_skill": {
          "move": "gust_slash",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.25,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di punggung bukit berangin",
            "location": "verdwall_forest_outer",
            "codex_gain": 25
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memakai Gust Slash",
            "location": "battle",
            "codex_gain": 20
          },
          {
            "source_type": "lore",
            "detail": "NPC: Pengembara di Papan Ekspedisi",
            "location": "hub",
            "codex_gain": 30
          },
          {
            "source_type": "lore",
            "detail": "Buku: Catatan Hutan",
            "location": "hub",
            "codex_gain": 25
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Secepat bisikan di dedaunan. Gustling jarang menyerang lebih dulu, tapi tak pernah kalah lari."
      },
      {
        "id": "014",
        "name": "Brookling",
        "types": [
          "Tide"
        ],
        "class": "Mystic",
        "role": "support",
        "rarity": "Uncommon",
        "bondable": true,
        "base_stats": {
          "hp": 25,
          "atk": 7,
          "def": 10,
          "sp_atk": 11,
          "sp_def": 11,
          "speed": 8
        },
        "growth_curve": {
          "hp": 5,
          "atk": 1,
          "def": 2,
          "sp_atk": 3,
          "sp_def": 3,
          "speed": 1
        },
        "abilities": [
          {
            "id": "clear_water",
            "name": "Clear Water",
            "unlock_level": 1,
            "desc": "Sedikit lebih tahan terhadap status."
          },
          {
            "id": "spring",
            "name": "Spring",
            "unlock_level": 12,
            "desc": "Memulihkan sedikit HP tiap giliran saat di bawah separuh."
          }
        ],
        "natural_skill": {
          "move": "bubble_veil",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "tide_mend"
        ],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.3,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di mata air tersembunyi",
            "location": "verdwall_forest_outer",
            "codex_gain": 20
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memakai Bubble Veil",
            "location": "battle",
            "codex_gain": 15
          },
          {
            "source_type": "habitat",
            "detail": "Amati ia muncul hanya saat kabut pagi",
            "location": "verdwall_forest_outer",
            "codex_gain": 15
          },
          {
            "source_type": "lore",
            "detail": "NPC: Tetua Desa Verdwall",
            "location": "hub",
            "codex_gain": 20
          },
          {
            "source_type": "lore",
            "detail": "Buku: Legenda Mata Air",
            "location": "hub",
            "codex_gain": 30
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Konon Brookling hanya menampakkan diri pada Seeker yang sabar menunggu kabut pagi terangkat."
      },
      {
        "id": "015",
        "name": "Mosswhim",
        "types": [
          "Nature"
        ],
        "class": "Guardian",
        "role": "tank",
        "rarity": "Rare",
        "bondable": true,
        "base_stats": {
          "hp": 34,
          "atk": 10,
          "def": 14,
          "sp_atk": 13,
          "sp_def": 13,
          "speed": 6
        },
        "growth_curve": {
          "hp": 6,
          "atk": 2,
          "def": 3,
          "sp_atk": 2,
          "sp_def": 2,
          "speed": 1
        },
        "abilities": [
          {
            "id": "mossbound",
            "name": "Mossbound",
            "unlock_level": 1,
            "desc": "Menerima 15% lebih sedikit damage."
          },
          {
            "id": "bloomtend",
            "name": "Bloomtend",
            "unlock_level": 12,
            "desc": "Memulihkan sedikit HP tiap giliran."
          }
        ],
        "natural_skill": {
          "move": "bramble_wall",
          "learn_level": 1
        },
        "custom_slot": 1,
        "tm_compat": [
          "spore_drift",
          "tide_mend"
        ],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_forest_outer"
        ],
        "wild_multiplier": 1.3,
        "info_sources": [
          {
            "source_type": "encounter",
            "detail": "Jumpa di rumpun tua berbunga",
            "location": "verdwall_forest_outer",
            "codex_gain": 15
          },
          {
            "source_type": "move_obs",
            "detail": "Lihat ia memasang Bramble Wall",
            "location": "battle",
            "codex_gain": 15
          },
          {
            "source_type": "habitat",
            "detail": "Amati ia berdiam menyerupai tunggul",
            "location": "verdwall_forest_outer",
            "codex_gain": 15
          },
          {
            "source_type": "lore",
            "detail": "NPC: Tetua Desa Verdwall",
            "location": "hub",
            "codex_gain": 25
          },
          {
            "source_type": "lore",
            "detail": "Buku: Catatan Hutan",
            "location": "hub",
            "codex_gain": 30
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Penjaga tua yang merawat sepetak bunga di telapak akarnya. Mosswhim menguji kesabaran sebelum mengakui seorang Seeker — sebuah tembok skill berlumut."
      },
      {
        "id": "099",
        "name": "Eldergrove",
        "types": [
          "Nature"
        ],
        "class": "Apex",
        "role": "tank",
        "rarity": "Regional Apex",
        "bondable": false,
        "base_stats": {
          "hp": 90,
          "atk": 16,
          "def": 14,
          "sp_atk": 18,
          "sp_def": 14,
          "speed": 8
        },
        "growth_curve": {
          "hp": 8,
          "atk": 2,
          "def": 2,
          "sp_atk": 3,
          "sp_def": 2,
          "speed": 1
        },
        "abilities": [
          {
            "id": "ancient_bark",
            "name": "Ancient Bark",
            "unlock_level": 1,
            "desc": "Menerima 20% lebih sedikit damage."
          },
          {
            "id": "awakening",
            "name": "Awakening",
            "unlock_level": 1,
            "desc": "Di bawah 50% HP, memasuki Fase Murka: damage naik tajam."
          }
        ],
        "natural_skill": {
          "move": "verdant_judgement",
          "learn_level": 1
        },
        "extra_moves": [
          "primal_crush"
        ],
        "custom_slot": 0,
        "tm_compat": [],
        "evolution": null,
        "region": "Verdwall",
        "habitat": [
          "verdwall_heart"
        ],
        "wild_multiplier": 1.0,
        "apex_rules": {
          "win_condition": "weaken_to_threshold",
          "threshold": 0,
          "phase_at": 0.5,
          "note": "TIDAK bisa di-Bond. 'Menaklukkan' = encounter klimaks + resolusi story thread. Memakai ulang sistem battle (fase + Awakening), bukan sistem baru."
        },
        "info_sources": [
          {
            "source_type": "lore",
            "detail": "Story thread Verdwall (teaser Luvirel/Merlyon)",
            "location": "hub",
            "codex_gain": 100
          }
        ],
        "sprite_paths": {
          "front": "",
          "back": "",
          "icon": ""
        },
        "dex_entry": "Bukan makhluk, melainkan kehendak hutan yang mengambil bentuk. Eldergrove tidak ditangkap — ia hanya bisa dipahami, lalu dilewati."
      }
    ]
  },
  "world": {
    "_note": "Konten dunia slice: Rank/GP (Bagian 3), Hub + 1 zona Verdwall (Bagian 6), titik interaksi & sumber lore Codex (Bagian 7). Semua data eksternal.",
    "ranks": [
      {
        "rank": 1,
        "name": "Wanderer",
        "gp_required": 0,
        "unlocks": "Start. Verdwall zona awal, 3 starter."
      },
      {
        "rank": 2,
        "name": "Trailblazer",
        "gp_required": 80,
        "unlocks": "Kontrak Hub, Verdwall lebih dalam."
      },
      {
        "rank": 3,
        "name": "Pathfinder",
        "gp_required": 200,
        "unlocks": "Jalur menuju Eldergrove (klimaks)."
      },
      {
        "rank": 4,
        "name": "Vanguard",
        "gp_required": 999,
        "unlocks": "Restricted zone — region lain (coming soon).",
        "placeholder": true
      },
      {
        "rank": 5,
        "name": "Sovereign",
        "gp_required": 999,
        "unlocks": "Endgame universe (coming soon).",
        "placeholder": true
      }
    ],
    "gp_rewards": {
      "story": 60,
      "contract": 35,
      "codex_complete": 25,
      "exploration": 12
    },
    "hub": {
      "name": "Outpost Verdwall",
      "interactions": [
        {
          "id": "npc_tetua",
          "name": "Tetua Desa Verdwall",
          "kind": "npc",
          "gives_lore_for": [
            "010",
            "014"
          ],
          "text": "“Cappin? Ah, makhluk topi itu. Ia menempel pada siapa pun yang tak memburunya. Brookling lebih pemalu — tunggu kabut, Nak.”"
        },
        {
          "id": "npc_lentera",
          "name": "Penjaga Lentera",
          "kind": "npc",
          "gives_lore_for": [
            "011"
          ],
          "text": "“Glimmoth datang ke cahaya, tapi hanya cahaya jamur tua. Lentera buatanku? Ia mencibir.”"
        },
        {
          "id": "npc_batu",
          "name": "Tukang Batu Hub",
          "kind": "npc",
          "gives_lore_for": [
            "012"
          ],
          "text": "“Batu yang kau pijak bisa jadi tertidur. Pebblion percaya pada kesabaran — dan benci dikejutkan.”"
        },
        {
          "id": "book_hutan",
          "name": "Buku: Catatan Hutan",
          "kind": "book",
          "gives_lore_for": [
            "010",
            "011",
            "013"
          ],
          "text": "Lembar-lembar lapuk berisi sketsa penghuni Verdwall: si topi spora, ngengat pendar, dan bayang angin di punggung bukit."
        },
        {
          "id": "book_mata_air",
          "name": "Buku: Legenda Mata Air",
          "kind": "book",
          "gives_lore_for": [
            "014"
          ],
          "text": "“...dan roh mata air hanya menampakkan wujud pada hati yang tak terburu.” — fragmen lontar Merlyon."
        },
        {
          "id": "npc_papan",
          "name": "Pengembara (Papan Ekspedisi)",
          "kind": "npc",
          "gives_lore_for": [
            "013"
          ],
          "text": "“Gustling? Aku kejar seharian, tak pernah kena. Akhirnya kubiarkan — ia malah mengikutiku pulang.”"
        }
      ]
    },
    "zone": {
      "id": "verdwall_forest_outer",
      "name": "Hutan Luar Verdwall",
      "size": {
        "w": 16,
        "h": 11
      },
      "exit": {
        "x": 1,
        "y": 9
      },
      "spawns": [
        {
          "cid": "010",
          "x": 5,
          "y": 3,
          "level": 7,
          "behavior": "graze"
        },
        {
          "cid": "011",
          "x": 11,
          "y": 2,
          "level": 7,
          "behavior": "wander"
        },
        {
          "cid": "012",
          "x": 13,
          "y": 7,
          "level": 8,
          "behavior": "still"
        },
        {
          "cid": "013",
          "x": 8,
          "y": 8,
          "level": 7,
          "behavior": "flee"
        },
        {
          "cid": "014",
          "x": 3,
          "y": 6,
          "level": 9,
          "behavior": "wander"
        },
        {
          "cid": "015",
          "x": 12,
          "y": 3,
          "level": 10,
          "behavior": "still"
        }
      ],
      "lore_points": [
        {
          "id": "lp_tua",
          "x": 5,
          "y": 2,
          "name": "Pohon Tua",
          "for": "010",
          "source_type": "habitat",
          "text": "Cappin merumput tenang di bawah pohon ini."
        },
        {
          "id": "lp_rock",
          "x": 13,
          "y": 6,
          "name": "Tepian Batu",
          "for": "012",
          "source_type": "habitat",
          "text": "Sebuah 'batu' bernapas pelan..."
        },
        {
          "id": "lp_mist",
          "x": 3,
          "y": 5,
          "name": "Mata Air Kabut",
          "for": "014",
          "source_type": "habitat",
          "text": "Kabut pagi menggantung; sesuatu berkilau di air."
        }
      ]
    },
    "missions": [
      {
        "id": "m_intro",
        "type": "story",
        "name": "Langkah Pertama Seeker",
        "desc": "Jelajah Hutan Luar, temui satu Crypture liar, dan menangkan pertarungan pertamamu.",
        "rank_req": 1,
        "gp": 60,
        "goal": {
          "kind": "win_any_battle"
        }
      },
      {
        "id": "m_codex",
        "type": "contract",
        "name": "Kontrak: Dokumentasi Cappin",
        "desc": "Isi Codex Cappin sampai 100% lalu Bond. Kunjungi NPC & buku di Hub untuk petunjuknya.",
        "rank_req": 1,
        "gp": 35,
        "goal": {
          "kind": "bond",
          "cid": "010"
        }
      },
      {
        "id": "m_eco",
        "type": "contract",
        "name": "Kontrak: Sensus Ekosistem",
        "desc": "Bond 2 Crypture liar berbeda untuk membuktikan kesiapanmu.",
        "rank_req": 2,
        "gp": 35,
        "goal": {
          "kind": "bond_count",
          "count": 2
        }
      },
      {
        "id": "m_apex",
        "type": "story",
        "name": "Jantung Verdwall",
        "desc": "Hadapi Eldergrove, sang Apex. Ia tak bisa di-Bond — lemahkan ia, dan tutup story thread Verdwall.",
        "rank_req": 3,
        "gp": 120,
        "goal": {
          "kind": "defeat_apex",
          "cid": "099"
        }
      }
    ]
  }
};
