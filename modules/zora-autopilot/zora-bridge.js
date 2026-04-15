const http = require("http");

const ZORA_HOST = "http://localhost:8788";
const WALLET = "0x0d08e9123ad0ca2a787088350d30853a941332c1";

async function zoraRequest(path) {
  return new Promise((resolve, reject) => {
    http.get(`${ZORA_HOST}${path}`, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ ok: false, raw: data });
        }
      });
    }).on("error", reject);
  });
}

async function getHealth()  { return zoraRequest("/health"); }
async function getStatus()  { return zoraRequest("/status"); }
async function getRevenue() { return zoraRequest("/status"); }
async function getCoins()   { return zoraRequest("/status"); }

module.exports = {
  WALLET,
  getHealth,
  getStatus,
  getRevenue,
  getCoins
};
