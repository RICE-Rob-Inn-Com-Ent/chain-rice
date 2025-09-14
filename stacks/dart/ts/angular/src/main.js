import { Component, NgModule } from '@angular/core'
import { BrowserModule } from '@angular/platform-browser'
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic'

@Component({
  selector: 'my-app',
  template: `
    <div style="font-family: system-ui; padding: 16px">
      <h1>Hello, {{name}}!</h1>
      <input [(ngModel)]="name" />
    </div>
  `
})
class AppComponent {
  name = 'World'
}

@NgModule({
  declarations: [AppComponent],
  imports: [BrowserModule],
  bootstrap: [AppComponent]
})
class AppModule {}

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err))


