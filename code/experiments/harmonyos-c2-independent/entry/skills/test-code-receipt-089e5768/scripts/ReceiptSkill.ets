import { scriptManager } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xC202;
const TAG = 'C2OwnReceipt';
const NONCE_PATTERN = /^[A-Za-z0-9-]{6,32}$/;

export default class ReceiptSkill {
  public async issueReceipt(info: scriptManager.ArkTSScriptInfo, ...args: string[]): Promise<void> {
    const receiptId = util.generateRandomUUID();
    const nonce = args[0] ?? '';
    const valid = NONCE_PATTERN.test(nonce);
    hilog.info(DOMAIN, TAG, 'event=skill_entered receipt=%{public}s valid=%{public}s', receiptId, String(valid));

    const result: scriptManager.ExecuteResult = valid ? {
      code: 0,
      result: {
        type: 'result',
        status: 'success',
        data: { nonce: nonce, receiptId: receiptId }
      }
    } : {
      code: -1,
      result: {
        type: 'result',
        status: 'failed',
        errCode: 'ERR_INVALID_NONCE',
        suggestion: '请输入由英文字母、数字或连字符组成的 6 到 32 位测试码。'
      }
    };

    hilog.info(DOMAIN, TAG, 'event=result_ready receipt=%{public}s code=%{public}d', receiptId, result.code);
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
      hilog.info(DOMAIN, TAG, 'event=result_reported receipt=%{public}s code=%{public}d', receiptId, result.code);
    } catch (error) {
      const failure = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'event=report_failed receipt=%{public}s error=%{public}d', receiptId, failure.code);
    }
  }
}
