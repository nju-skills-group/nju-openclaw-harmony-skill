import { UIAbility, Want } from '@kit.AbilityKit';
import { issueReceipt, trace } from './Receipt';

export default class ReceiptAbility extends UIAbility {
  onCreate(want: Want): void {
    const id = String(want.parameters?.requestId ?? '');
    const code = String(want.parameters?.code ?? '');
    trace('ability_entered', id, code);
    if (!/^[A-Za-z0-9-]{6,32}$/.test(code)) {
      void this.context.terminateSelfWithResult({ resultCode: 1 });
      return;
    }
    const receipt = issueReceipt(code);
    trace('ability_result', id, receipt);
    void this.context.terminateSelfWithResult({
      resultCode: 0,
      want: { parameters: { receipt } }
    }).catch(() => trace('ability_return_failed', id));
  }
}
