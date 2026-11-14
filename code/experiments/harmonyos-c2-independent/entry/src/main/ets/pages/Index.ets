@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('测试编号')
        .fontSize(26)
        .fontWeight(FontWeight.Medium)
      Text('com.skilllab.c2pc089e5768')
        .fontSize(16)
      Text('在小艺中调用测试编号技能，检查测试码和回执编号。')
        .fontSize(16)
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
