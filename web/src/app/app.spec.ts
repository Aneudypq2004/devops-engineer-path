import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';

import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should show the API version from /api/info', async () => {
    const fixture = TestBed.createComponent(App);
    const http = TestBed.inject(HttpTestingController);

    http.expectOne('/api/info').flush({
      name: 'DevOpsLab.Api',
      version: '1.0.0',
      environment: 'Production',
      host: 'devops-ubuntu',
      startedAt: '2026-01-01T00:00:00Z',
    });
    await fixture.whenStable();

    const footer = (fixture.nativeElement as HTMLElement).querySelector('footer');
    expect(footer?.textContent).toContain('API 1.0.0');
    http.verify();
  });
});
