import { http } from '@kit.NetworkKit';

interface Description { value: string; }
interface Current { temp_C: string; FeelsLikeC: string; humidity: string;
  windspeedKmph: string; precipMM: string; observation_time: string; weatherDesc: Description[]; }
interface Forecast { date: string; maxtempC: string; mintempC: string; }
interface Area { areaName: Description[]; region: Description[]; country: Description[]; }
interface WeatherResponse { current_condition: Current[]; nearest_area: Area[]; weather: Forecast[]; }
export interface WeatherData {
  requestedCity: string; resolvedLocation: string; temperatureC: string;
  feelsLikeC: string; humidityPercent: string; windKmph: string; precipitationMm: string;
  condition: string; observationTimeRaw: string; fetchedAt: string; source: string; forecast: Forecast[];
}
export async function queryWeather(cityInput: string): Promise<WeatherData> {
  const city = cityInput.trim();
  if (city.length === 0 || city.length > 120 || /[\r\n]/.test(city)) {
    throw new Error('ERR_INVALID_PARAMS');
  }
  const hosts: string[] = ['https://wttr.in/', 'https://wttr.is/'];
  for (let index = 0; index < hosts.length; index++) {
    const request = http.createHttp();
    try {
      const url = hosts[index] + encodeURIComponent(city) + '?format=j2';
      const response = await request.request(url, {
        method: http.RequestMethod.GET, expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000, readTimeout: 20000
      });
      if (response.responseCode !== 200) { throw new Error('ERR_SERVICE'); }
      const raw = JSON.parse(response.result as string) as WeatherResponse;
      if (!raw.current_condition || raw.current_condition.length === 0 ||
        !raw.nearest_area || raw.nearest_area.length === 0) { throw new Error('ERR_RESPONSE'); }
      const now = raw.current_condition[0];
      const area = raw.nearest_area[0];
      if (!now.temp_C || !now.humidity || !now.weatherDesc || !now.weatherDesc[0] ||
        !area.areaName || !area.areaName[0]) { throw new Error('ERR_RESPONSE'); }
      const location = area.areaName[0].value + ', ' +
        (area.region && area.region[0] ? area.region[0].value : '') + ', ' +
        (area.country && area.country[0] ? area.country[0].value : '');
      const forecast: Forecast[] = [];
      if (raw.weather) {
        raw.weather.forEach((day: Forecast) => {
          forecast.push({ date: day.date, maxtempC: day.maxtempC, mintempC: day.mintempC });
        });
      }
      console.info('WEATHER_PORT|query-success|source=' + hosts[index]);
      return { requestedCity: city, resolvedLocation: location, temperatureC: now.temp_C,
        feelsLikeC: now.FeelsLikeC, humidityPercent: now.humidity, windKmph: now.windspeedKmph,
        precipitationMm: now.precipMM, condition: now.weatherDesc[0].value,
        observationTimeRaw: now.observation_time, fetchedAt: new Date().toISOString(),
        source: url, forecast: forecast };
    } catch (error) {
      console.warn('WEATHER_PORT|attempt-failed|index=' + index);
    } finally { request.destroy(); }
  }
  throw new Error('ERR_WEATHER_UNAVAILABLE');
}
