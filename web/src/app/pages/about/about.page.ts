import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-about-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>About</h1>
    <p>Practice app for the DevOps lab: Angular served by Nginx, ASP.NET Core API on 127.0.0.1:5000, PostgreSQL.</p>
    <p>Reload this page in the browser. If you get a 404 from Nginx, the server is missing <code>try_files</code>.</p>
  `,
})
export class AboutPage {}
