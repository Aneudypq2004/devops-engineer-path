/** Must match TaskItem.TitleMaxLength in the API. */
export const TASK_TITLE_MAX_LENGTH = 200;

export interface TaskItem {
  id: number;
  title: string;
  isDone: boolean;
  createdAt: string;
  updatedAt: string | null;
}
