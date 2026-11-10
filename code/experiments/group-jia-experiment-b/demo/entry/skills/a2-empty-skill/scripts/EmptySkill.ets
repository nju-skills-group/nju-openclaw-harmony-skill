import { scriptManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class EmptySkill {
  public async ping(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    console.info(`A2 Empty Skill ping, args count: ${argv.length}`);

    const data: Record<string, Object> = {
      'message': 'A2 Skill is ready'
    };
    const payload: Record<string, Object> = {
      'type': 'result',
      'status': 'success',
      'data': data
    };

    await this.report(info, {
      code: 0,
      result: payload
    });
  }

  private async report(
    info: scriptManager.ArkTSScriptInfo,
    result: scriptManager.ExecuteResult
  ): Promise<void> {
    try {
      await scriptManager.completeArkTSScriptInApp(
        info.context,
        info.requestCode,
        result
      );
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(
        `Skill result report failed, code: ${businessError.code}, ` +
          `message: ${businessError.message}`
      );
    }
  }
}