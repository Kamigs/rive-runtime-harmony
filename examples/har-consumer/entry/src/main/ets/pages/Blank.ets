@Entry
@Component
struct ValidationBlankPage {
  aboutToAppear(): void {
    console.info('RiveValidation BLANK_PAGE appeared');
  }

  build() {
    Column({ space: 24 }) {
      Text('Rive 页面已退出').fontSize(24)
      Button('返回验收页面').id('return-page').onClick(() => {
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
      })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor('#F3F4F6')
  }
}
