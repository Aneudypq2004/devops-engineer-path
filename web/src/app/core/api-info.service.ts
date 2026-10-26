import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, map, of } from 'rxjs';

export interface ApiInfo {
  name: string;
  version: string;
  environment: string;
  host: string;
  startedAt: string;
}

export type ApiStatus =
  | { state: 'checking' }
  | { state: 'up'; info: ApiInfo }
  | { state: 'down' };

@Injectable({ providedIn: 'root' })
export class ApiInfoService {
  private readonly http = inject(HttpClient);

  getStatus(): Observable<ApiStatus> {
    return this.http.get<ApiInfo>('/api/info').pipe(
      map((info): ApiStatus => ({ state: 'up', info })),
      catchError(() => of<ApiStatus>({ state: 'down' })),
    );
  }
}
