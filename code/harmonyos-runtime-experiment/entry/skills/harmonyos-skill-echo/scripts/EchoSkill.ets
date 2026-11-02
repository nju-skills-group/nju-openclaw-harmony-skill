import { scriptManager } from '@kit.AbilityKit';
import { echoMessage } from './EchoBusiness';

export default class EchoSkill {
  public async echo(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const rawMessage = argv.length > 0 && argv[0].trim().length > 0
      ? argv[0].trim()
      : 'Hello from the HarmonyOS Skill demo.';
    const message: string = echoMessage(rawMessage) as string;

    const result: scriptManager.ExecuteResult = {
      code: 0,
      result: {
        type: 'result',
        status: 'success',
        data: { message: message }
      }
    };

    await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
  }
}
