import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { TaskItem } from '../models/task.model';

@Injectable({ providedIn: 'root' })
export class TasksService {
  private readonly http = inject(HttpClient);
  // Relative URL: Nginx (server) or proxy.conf.json (ng serve) forwards /api to the .NET API.
  private readonly baseUrl = '/api/tasks';

  getAll(): Observable<TaskItem[]> {
    return this.http.get<TaskItem[]>(this.baseUrl);
  }

  create(title: string): Observable<TaskItem> {
    return this.http.post<TaskItem>(this.baseUrl, { title });
  }

  update(task: TaskItem): Observable<TaskItem> {
    return this.http.put<TaskItem>(`${this.baseUrl}/${task.id}`, {
      title: task.title,
      isDone: task.isDone,
    });
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
