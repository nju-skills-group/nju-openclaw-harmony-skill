import { scriptManager } from '@kit.AbilityKit';
import { echoMessage } from './EchoBusiness';
import { benchWork, BENCH_SIZE } from '../../../src/main/ets/bench/BenchWork';
import { logLine } from '../../../src/main/ets/bench/BenchLog';

export default class EchoSkill {
  public async echo(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const t0: number = Date.now();
    const rawMessage = argv.length > 0 && argv[0].trim().length > 0
      ? argv[0].trim()
      : 'Hello from the HarmonyOS Skill demo.';
    const message: string = echoMessage(rawMessage) as string;
    const checksum: number = benchWork(BENCH_SIZE);
    const t1: number = Date.now();

    const result: scriptManager.ExecuteResult = {
      code: 0,
      result: {
        type: 'result',
        status: 'success',
        data: { message: message, checksum: checksum }
      }
    };

    await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    const t2: number = Date.now();
    // biz = entry to result built; total = entry to result reported.
    logLine('SAMPLE|SKILL|invoke|seq=0|total=' + (t2 - t0) + '|biz=' + (t1 - t0) +
      '|bridge=0|load=0|checksum=' + checksum + '|ok=1');
  }
}
