import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

export const BUNDLE = 'com.skilllab.c34agent089e5768';
export const DOMAIN = 0xC304;
export const TAG = 'C34OwnAgent';

export function matchReceipt(text: string): string {
  return /^(?:生成回执|回执)\s+([A-Za-z0-9-]{6,32})$/.exec(text.trim())?.[1] ?? '';
}

export function issueReceipt(code: string): string {
  return `${code} ${util.generateRandomUUID()}`;
}

export function trace(event: string, id: string, value: string = ''): void {
  hilog.info(DOMAIN, TAG, '%{public}s id=%{public}s %{public}s', event, id, value);
}
