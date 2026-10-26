import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';

import { TASK_TITLE_MAX_LENGTH, TaskItem } from './models/task.model';
import { TasksService } from './services/tasks.service';

@Component({
  selector: 'app-tasks-page',
  imports: [FormsModule],
  templateUrl: './tasks.page.html',
  styleUrl: './tasks.page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TasksPage {
  private readonly tasksService = inject(TasksService);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly titleMaxLength = TASK_TITLE_MAX_LENGTH;
  protected readonly tasks = signal<TaskItem[]>([]);
  protected readonly isLoading = signal(true);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly newTitle = signal('');
  protected readonly canAdd = computed(() => this.newTitle().trim().length > 0);
  protected readonly pendingCount = computed(() => this.tasks().filter((task) => !task.isDone).length);

  constructor() {
    this.loadTasks();
  }

  protected loadTasks(): void {
    this.isLoading.set(true);
    this.tasksService
      .getAll()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (tasks) => {
          this.tasks.set(tasks);
          this.errorMessage.set(null);
          this.isLoading.set(false);
        },
        error: (error: HttpErrorResponse) => this.showError(error),
      });
  }

  protected addTask(): void {
    const title = this.newTitle().trim();
    if (!title) {
      return;
    }

    this.tasksService
      .create(title)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (task) => {
          this.tasks.update((tasks) => [task, ...tasks]);
          this.newTitle.set('');
          this.errorMessage.set(null);
        },
        error: (error: HttpErrorResponse) => this.showError(error),
      });
  }

  protected toggleDone(task: TaskItem): void {
    this.tasksService
      .update({ ...task, isDone: !task.isDone })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (updated) => this.replaceTask(updated),
        error: (error: HttpErrorResponse) => this.showError(error),
      });
  }

  protected deleteTask(task: TaskItem): void {
    this.tasksService
      .delete(task.id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => this.tasks.update((tasks) => tasks.filter((t) => t.id !== task.id)),
        error: (error: HttpErrorResponse) => this.showError(error),
      });
  }

  private replaceTask(updated: TaskItem): void {
    this.tasks.update((tasks) => tasks.map((task) => (task.id === updated.id ? updated : task)));
  }

  private showError(error: HttpErrorResponse): void {
    this.isLoading.set(false);
    // Keep the raw status visible: 502 = API down, 504 = API too slow, 500 = check journalctl.
    const status = error.status === 0 ? 'network error' : `${error.status} ${error.statusText}`;
    this.errorMessage.set(`Request failed: ${status.trim()}`);
  }
}
