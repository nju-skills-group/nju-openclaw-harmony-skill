import { scriptManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { trace } from '../../../src/main/ets/Receipt';
import { getCurrentWeather } from '../../../src/main/ets/WeatherService';

export default class WeatherSkill {
  public async getCurrentWeather(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const id = info.requestCode;
    trace('weather_app_skill_entered', id);
    const weather = await getCurrentWeather(argv[0] ?? '', id);
    const result: scriptManager.ExecuteResult = {
      code: weather.status === 'success' ? 0 : -1,
      result: {
        type: 'result',
        status: weather.status === 'success' ? 'success' : 'failed',
        data: weather
      }
    };
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, id, result);
      trace('weather_app_skill_reported', id, JSON.stringify(weather));
    } catch (error) {
      trace('weather_app_skill_report_failed', id, String((error as BusinessError).code));
    }
  }
}
