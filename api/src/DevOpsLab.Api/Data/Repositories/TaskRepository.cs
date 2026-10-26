using DevOpsLab.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace DevOpsLab.Api.Data.Repositories;

public class TaskRepository(AppDbContext db) : ITaskRepository
{
    public async Task<IReadOnlyList<TaskItem>> GetAllAsync(CancellationToken cancellationToken) =>
        await db.Tasks
            .AsNoTracking()
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync(cancellationToken);

    public Task<TaskItem?> GetByIdAsync(int id, CancellationToken cancellationToken) =>
        db.Tasks.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public void Add(TaskItem task) => db.Tasks.Add(task);

    public void Remove(TaskItem task) => db.Tasks.Remove(task);

    public Task SaveChangesAsync(CancellationToken cancellationToken) => db.SaveChangesAsync(cancellationToken);
}
