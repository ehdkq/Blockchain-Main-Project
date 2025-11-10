import { ethers as ethersV6 } from "ethers";
import * as fs from "fs";

const RPC = process.env.RPC_URL ?? "http://127.0.0.1:8545";
const N = Number(process.env.N_CALLS ?? 25);

async function main() {
  const provider = new ethersV6.JsonRpcProvider(RPC);
  const rows: string[] = ["idx,ms"];
  for (let i = 0; i < N; i++) {
    const t0 = Date.now();
    await provider.getBlockNumber();
    rows.push(`${i},${Date.now() - t0}`);
  }

  fs.mkdirSync("artifacts/metrics", { recursive: true });
  fs.writeFileSync("artifacts/metrics/perf_latency.csv", rows.join("\n"));

  const times = rows.slice(1).map(r => Number(r.split(",")[1]));
  const mean = times.reduce((a,b)=>a+b,0)/times.length;
  const sorted = [...times].sort((a,b)=>a-b);
  const p50 = sorted[Math.floor(0.50*(sorted.length-1))];
  const p95 = sorted[Math.floor(0.95*(sorted.length-1))];

  const summary = { N: times.length, mean_ms: mean, p50_ms: p50, p95_ms: p95 };
  fs.writeFileSync("artifacts/metrics/perf_latency.json", JSON.stringify(summary, null, 2));
  console.log("PERF_SUMMARY", summary);
}

main().catch((e) => { console.error(e); process.exit(1); });
