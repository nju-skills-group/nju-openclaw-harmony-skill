// Deterministic business workload. The JS page (rawfile/bench.html) contains
// a line-by-line equivalent: benchWork(n). Keep both in sync.
export const BENCH_SIZE: number = 50000;

export function benchWork(n: number): number {
  let seed: number = 12345;
  const arr: number[] = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    seed = (seed * 1103515245 + 12345) % 2147483648;
    arr[i] = seed;
  }
  arr.sort((a: number, b: number): number => a - b);
  let sum: number = 0;
  for (let i = 0; i < n; i++) {
    sum = (sum + arr[i]) % 1000000007;
  }
  return sum;
}
