import { scriptManager } from '@kit.AbilityKit';
import { queryWeather } from './WeatherService';
export default class WeatherSkill {
  public async query(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    console.info('WEATHER_PORT|skill-enter');
    let result: scriptManager.ExecuteResult;
    if (argv.length !== 1 || argv[0].trim().length === 0 || argv[0].trim().length > 120) {
      result = { code: -1, result: { type: 'result', status: 'failed',
        errCode: 'ERR_INVALID_PARAMS', errMsg: 'Provide one city, region, airport code or coordinates.' } };
    } else {
      try {
        const weather = await queryWeather(argv[0]);
        result = { code: 0, result: { type: 'result', status: 'success', data: weather } };
      } catch (error) {
        result = { code: -2, result: { type: 'result', status: 'failed',
          errCode: 'ERR_WEATHER_UNAVAILABLE', errMsg: 'Weather services did not return usable data.',
          suggestion: 'Check the location and network, then retry.' } };
      }
    }
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
      console.info('WEATHER_PORT|skill-complete|code=' + result.code);
    } catch (error) { console.error('WEATHER_PORT|callback-failed|' + String(error)); }
  }
}
