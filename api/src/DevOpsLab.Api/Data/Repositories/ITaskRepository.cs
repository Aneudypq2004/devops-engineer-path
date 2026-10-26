using DevOpsLab.Api.Domain;

namespace DevOpsLab.Api.Data.Repositories;

public interface ITaskRepository
{
    Task<IReadOnlyList<TaskItem>> GetAllAsync(CancellationToken cancellationToken);
    Task<TaskItem?> GetByIdAsync(int id, CancellationToken cancellationToken);
    void Add(TaskItem task);
    void Remove(TaskItem task);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
