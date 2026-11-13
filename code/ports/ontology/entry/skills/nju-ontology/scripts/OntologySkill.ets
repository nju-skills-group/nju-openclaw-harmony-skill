import { scriptManager } from '@kit.AbilityKit';
import { OntologyStore, StoreResult } from './OntologyStore';

class EmptyResultData {
}

export default class OntologySkill {
  public async createEntity(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const store: OntologyStore = new OntologyStore(info.context);
    const outcome: StoreResult = argv.length >= 3
      ? await store.createEntity(argv[0].trim(), argv[1].trim(), argv[2])
      : this.invalid('createEntity requires arg1, arg2 and arg3');
    await this.report(info, outcome);
  }

  public async getEntity(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const store: OntologyStore = new OntologyStore(info.context);
    const outcome: StoreResult = argv.length >= 1
      ? await store.getEntity(argv[0].trim())
      : this.invalid('getEntity requires arg1');
    await this.report(info, outcome);
  }

  public async listEntities(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const store: OntologyStore = new OntologyStore(info.context);
    const outcome: StoreResult = argv.length >= 1
      ? await store.listEntities(argv[0].trim())
      : this.invalid('listEntities requires arg1');
    await this.report(info, outcome);
  }

  private invalid(message: string): StoreResult {
    return {
      ok: false,
      errCode: 'ERR_INVALID_PARAMS',
      errMsg: message,
      suggestion: '请按 SKILL.md 的参数 Schema 重新调用。'
    };
  }

  private async report(info: scriptManager.ArkTSScriptInfo, outcome: StoreResult): Promise<void> {
    const result: scriptManager.ExecuteResult = outcome.ok
      ? {
          code: 0,
          result: {
            type: 'result',
            status: 'success',
            data: outcome.data ?? new EmptyResultData()
          }
        }
      : {
          code: -1,
          result: {
            type: 'result',
            status: 'failed',
            errCode: outcome.errCode ?? 'ERR_INTERNAL',
            errMsg: outcome.errMsg ?? 'unknown error',
            suggestion: outcome.suggestion ?? '请稍后重试。'
          }
        };

    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (error) {
      console.error(`completeArkTSScriptInApp failed: ${String(error)}`);
    }
  }
}

