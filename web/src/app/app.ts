import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { ApiInfoService, ApiStatus } from './core/api-info.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {
  protected readonly apiStatus = toSignal(inject(ApiInfoService).getStatus(), {
    initialValue: { state: 'checking' } as ApiStatus,
  });

  protected readonly apiInfo = computed(() => {
    const status = this.apiStatus();
    return status.state === 'up' ? status.info : null;
  });
}
