import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { trace } from './Receipt';

interface TextValue {
  value?: string;
}

interface WeatherCondition {
  temp_C?: string;
  weatherDesc?: TextValue[];
  observation_time?: string;
}

interface WeatherArea {
  areaName?: TextValue[];
}

interface WeatherResponse {
  current_condition?: WeatherCondition[];
  nearest_area?: WeatherArea[];
}

export interface WeatherResult {
  status: string;
  location?: string;
  temperatureC?: number;
  condition?: string;
  observationTime?: string;
  reason?: string;
}

export async function getCurrentWeather(city: string, id: string, timeoutMs: number = 10000): Promise<WeatherResult> {
  const query = city.trim();
  if (!/^[\u4e00-\u9fffA-Za-z][\u4e00-\u9fffA-Za-z .'-]{0,59}$/.test(query)) {
    return { status: 'clarification', reason: '请提供要查询的城市。' };
  }
  const place = query === '南京' ? 'Nanjing' : query;
  const url = `https://wttr.in/${encodeURIComponent(place)}?format=j1`;
  const request = http.createHttp();
  trace('weather_tool_start', id, `city=${place} timeout_ms=${timeoutMs}`);
  try {
    const response = await request.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: timeoutMs,
      readTimeout: timeoutMs
    });
    trace('weather_tool_http', id, String(response.responseCode));
    if (response.responseCode !== 200 || typeof response.result !== 'string') {
      return { status: 'failed', reason: `天气服务请求失败（HTTP ${response.responseCode}）。` };
    }
    const data = JSON.parse(response.result) as WeatherResponse;
    const current = data?.current_condition?.[0];
    const location = data?.nearest_area?.[0]?.areaName?.[0]?.value?.trim();
    const condition = current?.weatherDesc?.[0]?.value?.trim();
    const rawTemperature = current?.temp_C?.trim();
    const temperatureC = Number(rawTemperature);
    if (!location || !condition || !rawTemperature || !Number.isFinite(temperatureC)) {
      return { status: 'failed', reason: '天气服务返回字段不完整。' };
    }
    return { status: 'success', location, temperatureC, condition, observationTime: current?.observation_time };
  } catch (error) {
    const code = (error as BusinessError).code;
    trace('weather_tool_error', id, String(code));
    return { status: 'failed', reason: code === 2300028 ? '查询超时。' : '天气查询失败。' };
  } finally {
    request.destroy();
  }
}
