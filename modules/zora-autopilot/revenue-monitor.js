require("dotenv").config();
const fs = require("fs");
const http = require("http");

const API_KEY = process.env.ZORA_API_KEY;
const IDENTIFIER = process.env.ZORA_IDENTIFIER;
const HUB_WALLET = (process.env.HUB_WALLET || "").toLowerCase();
const POLL_INTERVAL_MS = Number(process.env.POLL_INTERVAL_MS || 3600000);
const PORT = Number(process.env.PORT || 8788);
const OUTPUT_JSON = process.env.OUTPUT_JSON || "./last-report.json";
const BASE_URL = "https://api-sdk.zora.engineering";

let lastReport = {
  ok: false,
  timestamp: new Date().toISOString(),
  summary: {},
  hotCoins: [],
  maintainAndPromote: [],
  dormantWithHolders: [],
  payoutIssues: [],
  referrerIssues: [],
  errors: []
};

function num(v) {
  const n = parseFloat(v ?? 0);
  return Number.isFinite(n) ? n : 0;
}

async function fetchJson(url, headers = {}) {
  const res = await fetch(url, { headers });
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} su ${url}`);
  }
  return await res.json();
}

async function fetchProfileCoins() {
  const url = `${BASE_URL}/profileCoins?identifier=${encodeURIComponent(IDENTIFIER)}&count=100`;
  const data = await fetchJson(url, { "api-key": API_KEY });
  const edges = data?.profile?.createdCoins?.edges || [];
  return edges.map(e => e.node).filter(Boolean);
}

function analyzeCoins(coins) {
  const activeCoins = [];
  const hotCoins = [];
  const dormantWithHolders = [];
  const zeroMarketCap = [];
  const payoutIssues = [];
  const referrerIssues = [];
  const maintainAndPromote = [];

  let totalMarketCap = 0;
  let totalVolume24h = 0;
  let totalVolume = 0;

  for (const c of coins) {
    const marketCap = num(c.marketCap);
    const volume24h = num(c.volume24h);
    const totalVol = num(c.totalVolume);
    const holders = Number(c.uniqueHolders || 0);
    const payout = String(c.payoutRecipient || "").toLowerCase();
    const referrer = String(c.platformReferrerAddress || c.platformReferrer || "").toLowerCase();

    totalMarketCap += marketCap;
    totalVolume24h += volume24h;
    totalVolume += totalVol;

    const item = {
      name: c.name || c.symbol || c.address || "unknown",
      address: c.address,
      marketCap,
      volume24h,
      totalVolume: totalVol,
      uniqueHolders: holders,
      payoutRecipient: c.payoutRecipient || null,
      platformReferrer: c.platformReferrerAddress || c.platformReferrer || null,
      zoraLink: c.zoraLink || null
    };

    if (marketCap > 0) activeCoins.push(item);
    if (marketCap === 0) zeroMarketCap.push(item);
    if (volume24h > 0.1) hotCoins.push(item);
    if (volume24h > 0) maintainAndPromote.push(item);
    if (holders >= 2 && volume24h === 0) dormantWithHolders.push(item);

    if (HUB_WALLET && payout && payout !== HUB_WALLET) {
      payoutIssues.push({
        name: item.name,
        address: item.address,
        currentPayout: payout
      });
    }

    if (!referrer || /^0x0{40}$/.test(referrer)) {
      referrerIssues.push({
        name: item.name,
        address: item.address,
        currentReferrer: referrer || null
      });
    }
  }

  hotCoins.sort((a, b) => b.volume24h - a.volume24h);
  maintainAndPromote.sort((a, b) => b.volume24h - a.volume24h);
  dormantWithHolders.sort((a, b) => b.uniqueHolders - a.uniqueHolders || b.marketCap - a.marketCap);
  activeCoins.sort((a, b) => b.marketCap - a.marketCap);

  return {
    ok: true,
    timestamp: new Date().toISOString(),
    summary: {
      totalCoins: coins.length,
      activeCoins: activeCoins.length,
      zeroMarketCap: zeroMarketCap.length,
      hotCoins: hotCoins.length,
      dormantWithHolders: dormantWithHolders.length,
      payoutIssues: payoutIssues.length,
      referrerIssues: referrerIssues.length,
      totalMarketCap: Number(totalMarketCap.toFixed(4)),
      totalVolume24h: Number(totalVolume24h.toFixed(4)),
      totalVolume: Number(totalVolume.toFixed(4)),
      estimatedCreatorFees: Number((totalVolume * 0.01 * 0.5).toFixed(6))
    },
    hotCoins,
    maintainAndPromote,
    dormantWithHolders,
    payoutIssues,
    referrerIssues,
    topByMarketCap: activeCoins.slice(0, 10)
  };
}

async function monitorRevenue() {
  try {
    const coins = await fetchProfileCoins();
    lastReport = analyzeCoins(coins);
    fs.writeFileSync(OUTPUT_JSON, JSON.stringify(lastReport, null, 2), "utf8");

    console.log("============================================================");
    console.log(`📊 Revenue Report [${lastReport.timestamp}]`);
    console.log("============================================================");
    console.log(`Coin attivi:              ${lastReport.summary.activeCoins}/${lastReport.summary.totalCoins}`);
    console.log(`Market Cap totale:        $${lastReport.summary.totalMarketCap}`);
    console.log(`Volume 24h totale:        $${lastReport.summary.totalVolume24h}`);
    console.log(`Volume totale:            $${lastReport.summary.totalVolume}`);
    console.log(`Fee stimate:              $${lastReport.summary.estimatedCreatorFees}`);
    console.log(`Payout issues:            ${lastReport.summary.payoutIssues}`);
    console.log(`Referrer issues:          ${lastReport.summary.referrerIssues}`);
    console.log(`Dormant con holders >=2:  ${lastReport.summary.dormantWithHolders}`);
    console.log("");

    if (lastReport.maintainAndPromote.length) {
      console.log("🟢 COIN DA MANTENERE E PROMUOVERE");
      lastReport.maintainAndPromote.slice(0, 10).forEach(c => {
        console.log(` - ${c.name} | vol24h=$${c.volume24h} | MC=$${c.marketCap} | holders=${c.uniqueHolders} | ${c.address}`);
      });
      console.log("");
    }

    if (lastReport.dormantWithHolders.length) {
      console.log("🟡 COIN DORMANT CON HOLDERS (solo review manuale)");
      lastReport.dormantWithHolders.slice(0, 10).forEach(c => {
        console.log(` - ${c.name} | holders=${c.uniqueHolders} | vol24h=$${c.volume24h} | MC=$${c.marketCap} | ${c.address}`);
      });
      console.log("");
    }

    if (lastReport.payoutIssues.length) {
      console.log("⚠️ PAYOUT RECIPIENT DA CONTROLLARE");
      lastReport.payoutIssues.slice(0, 10).forEach(c => {
        console.log(` - ${c.name} | payout=${c.currentPayout}`);
      });
      console.log("");
    }

    if (lastReport.referrerIssues.length) {
      console.log("💸 PLATFORM REFERRER ASSENTE / ZERO");
      lastReport.referrerIssues.slice(0, 10).forEach(c => {
        console.log(` - ${c.name} | referrer=${c.currentReferrer}`);
      });
      console.log("");
    }
  } catch (err) {
    lastReport = {
      ok: false,
      timestamp: new Date().toISOString(),
      summary: {},
      hotCoins: [],
      maintainAndPromote: [],
      dormantWithHolders: [],
      payoutIssues: [],
      referrerIssues: [],
      errors: [String(err?.stack || err)]
    };
    fs.writeFileSync(OUTPUT_JSON, JSON.stringify(lastReport, null, 2), "utf8");
    console.error("Errore monitorRevenue:", err);
  }
}

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({
      ok: true,
      service: "zora-autopilot",
      timestamp: new Date().toISOString()
    }));
  }

  if (req.url === "/status") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(lastReport, null, 2));
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ ok: false, error: "Not found" }));
});

async function main() {
  await monitorRevenue();
  setInterval(monitorRevenue, POLL_INTERVAL_MS);
  server.listen(PORT, () => {
    console.log(`Zora autopilot listening on http://localhost:${PORT}`);
  });
}

main().catch(err => {
  console.error("Fatal error:", err);
  process.exit(1);
});
