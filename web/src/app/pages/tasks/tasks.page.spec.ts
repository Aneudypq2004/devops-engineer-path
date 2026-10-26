import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

import { TasksPage } from './tasks.page';
import { TaskItem } from './models/task.model';

const sampleTask: TaskItem = {
  id: 1,
  title: 'Install Nginx',
  isDone: false,
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: null,
};

describe('TasksPage', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [TasksPage],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('lists the tasks returned by the API', async () => {
    const fixture = TestBed.createComponent(TasksPage);

    http.expectOne('/api/tasks').flush([sampleTask]);
    await fixture.whenStable();

    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('.task-list')?.textContent).toContain('Install Nginx');
    expect(element.querySelector('.subtitle')?.textContent).toContain('1 pending of 1');
  });

  it('shows the HTTP status when the API fails', async () => {
    const fixture = TestBed.createComponent(TasksPage);

    http.expectOne('/api/tasks').flush('Bad Gateway', { status: 502, statusText: 'Bad Gateway' });
    await fixture.whenStable();

    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('.error')?.textContent).toContain('502 Bad Gateway');
  });
});
