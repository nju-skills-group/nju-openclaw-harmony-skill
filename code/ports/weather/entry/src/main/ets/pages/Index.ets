import { queryWeather } from '../../../../skills/harmonyos-weather/scripts/WeatherService';
@Entry
@Component
struct Index {
  @State city: string = 'Shanghai';
  @State result: string = '输入城市、地区、机场代码或经纬度，查询当前天气和预报。';
  @State loading: boolean = false;
  async lookup(): Promise<void> {
    if (this.city.trim().length === 0) { this.result = '请输入查询地点。'; return; }
    this.loading = true;
    try {
      const data = await queryWeather(this.city);
      let report = data.resolvedLocation + '\n' + data.condition + '  ' + data.temperatureC + '°C' +
        '\n体感 ' + data.feelsLikeC + '°C  湿度 ' + data.humidityPercent + '%' +
        '\n风速 ' + data.windKmph + ' km/h  降水 ' + data.precipitationMm + ' mm\n';
      data.forecast.forEach((day) => { report += '\n' + day.date + '  ' + day.mintempC + '–' + day.maxtempC + '°C'; });
      this.result = report + '\n\n查询时间：' + data.fetchedAt + '\n来源：' + data.source;
    } catch (error) { this.result = '暂时无法获取天气。请检查地点或网络后重试。'; }
    finally { this.loading = false; }
  }
  build() {
    Column({ space: 20 }) {
      Text('天气查询').fontSize(30).fontWeight(FontWeight.Bold)
      TextInput({ text: this.city, placeholder: '例如 Shanghai、南京或 31.2,121.5' })
        .onChange((value: string) => { this.city = value; })
      Button(this.loading ? '查询中…' : '查询天气').enabled(!this.loading)
        .onClick(() => { this.lookup(); })
      Scroll() { Text(this.result).fontSize(20).copyOption(CopyOptions.InApp).width('100%') }.layoutWeight(1)
    }.padding(40).width('100%').height('100%')
  }
}
