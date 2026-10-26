using System.Diagnostics.CodeAnalysis;
using DevOpsLab.Api.Contracts;
using DevOpsLab.Api.Data.Repositories;
using DevOpsLab.Api.Domain;

namespace DevOpsLab.Api.Services;

public class TaskService(ITaskRepository repository, TimeProvider timeProvider)
{
    private static readonly string InvalidTitleMessage =
        $"Title is required and must be at most {TaskItem.TitleMaxLength} characters.";

    public async Task<IReadOnlyList<TaskResponse>> GetAllAsync(CancellationToken cancellationToken)
    {
        var tasks = await repository.GetAllAsync(cancellationToken);
        return tasks.Select(ToResponse).ToList();
    }

    public async Task<ServiceResult<TaskResponse>> GetByIdAsync(int id, CancellationToken cancellationToken)
    {
        var task = await repository.GetByIdAsync(id, cancellationToken);
        return task is null
            ? TaskNotFound<TaskResponse>(id)
            : ServiceResult<TaskResponse>.Ok(ToResponse(task));
    }

    public async Task<ServiceResult<TaskResponse>> CreateAsync(CreateTaskRequest request, CancellationToken cancellationToken)
    {
        if (!TryNormalizeTitle(request.Title, out var title))
        {
            return ServiceResult<TaskResponse>.Fail(InvalidTitleMessage);
        }

        var task = new TaskItem { Title = title, CreatedAt = timeProvider.GetUtcNow() };
        repository.Add(task);
        await repository.SaveChangesAsync(cancellationToken);

        return ServiceResult<TaskResponse>.Ok(ToResponse(task), "Task created.");
    }

    public async Task<ServiceResult<TaskResponse>> UpdateAsync(int id, UpdateTaskRequest request, CancellationToken cancellationToken)
    {
        if (!TryNormalizeTitle(request.Title, out var title))
        {
            return ServiceResult<TaskResponse>.Fail(InvalidTitleMessage);
        }

        var task = await repository.GetByIdAsync(id, cancellationToken);
        if (task is null)
        {
            return TaskNotFound<TaskResponse>(id);
        }

        task.Title = title;
        task.IsDone = request.IsDone;
        task.UpdatedAt = timeProvider.GetUtcNow();
        await repository.SaveChangesAsync(cancellationToken);

        return ServiceResult<TaskResponse>.Ok(ToResponse(task), "Task updated.");
    }

    public async Task<ServiceResult<bool>> DeleteAsync(int id, CancellationToken cancellationToken)
    {
        var task = await repository.GetByIdAsync(id, cancellationToken);
        if (task is null)
        {
            return TaskNotFound<bool>(id);
        }

        repository.Remove(task);
        await repository.SaveChangesAsync(cancellationToken);

        return ServiceResult<bool>.Ok(true, "Task deleted.");
    }

    // [Required] lets "   " through, so the title is trimmed and checked again here.
    private static bool TryNormalizeTitle(string? title, [NotNullWhen(true)] out string? normalizedTitle)
    {
        normalizedTitle = title?.Trim();
        return !string.IsNullOrEmpty(normalizedTitle) && normalizedTitle.Length <= TaskItem.TitleMaxLength;
    }

    private static ServiceResult<TData> TaskNotFound<TData>(int id) =>
        ServiceResult<TData>.Fail($"Task {id} was not found.", ServiceErrorType.NotFound);

    private static TaskResponse ToResponse(TaskItem task) =>
        new(task.Id, task.Title, task.IsDone, task.CreatedAt, task.UpdatedAt);
}
