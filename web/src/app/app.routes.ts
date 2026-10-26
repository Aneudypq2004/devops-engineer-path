import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./pages/tasks/tasks.page').then((m) => m.TasksPage),
    title: 'Tasks · DevOps Lab',
  },
  {
    // Reload this route on the server: without try_files in Nginx you get a 404 (Phase 2 challenge).
    path: 'about',
    loadComponent: () => import('./pages/about/about.page').then((m) => m.AboutPage),
    title: 'About · DevOps Lab',
  },
  { path: '**', redirectTo: '' },
];
