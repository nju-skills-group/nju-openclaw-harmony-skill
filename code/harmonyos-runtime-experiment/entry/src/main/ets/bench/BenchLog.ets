import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xD001;
const TAG: string = 'BenchD';

// One line per sample. Fields are separated by '|' so the lines can be
// parsed by bench/stats.ps1 without any JSON round-trip.
export function logLine(line: string): void {
  hilog.info(DOMAIN, TAG, '%{public}s', line);
}
