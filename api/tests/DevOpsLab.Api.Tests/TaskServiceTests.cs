using DevOpsLab.Api.Contracts;
using DevOpsLab.Api.Data;
using DevOpsLab.Api.Data.Repositories;
using DevOpsLab.Api.Domain;
using DevOpsLab.Api.Services;
using Microsoft.EntityFrameworkCore;

namespace DevOpsLab.Api.Tests;

public sealed class TaskServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly TaskService _service;

    public TaskServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new AppDbContext(options);
        _service = new TaskService(new TaskRepository(_db), TimeProvider.System);
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task Create_trims_the_title_and_saves_the_task()
    {
        var result = await _service.CreateAsync(new CreateTaskRequest("  Configure ufw  "), CancellationToken.None);

        Assert.True(result.Success);
        Assert.Equal("Configure ufw", result.Data!.Title);
        Assert.Equal(1, await _db.Tasks.CountAsync());
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public async Task Create_rejects_a_blank_title(string title)
    {
        var result = await _service.CreateAsync(new CreateTaskRequest(title), CancellationToken.None);

        Assert.False(result.Success);
        Assert.Equal(ServiceErrorType.Validation, result.ErrorType);
        Assert.Equal(0, await _db.Tasks.CountAsync());
    }

    [Fact]
    public async Task Create_rejects_a_title_longer_than_the_maximum()
    {
        var tooLong = new string('a', TaskItem.TitleMaxLength + 1);

        var result = await _service.CreateAsync(new CreateTaskRequest(tooLong), CancellationToken.None);

        Assert.False(result.Success);
        Assert.Equal(ServiceErrorType.Validation, result.ErrorType);
    }

    [Fact]
    public async Task Update_returns_not_found_for_a_missing_task()
    {
        var result = await _service.UpdateAsync(999, new UpdateTaskRequest("Anything", true), CancellationToken.None);

        Assert.False(result.Success);
        Assert.Equal(ServiceErrorType.NotFound, result.ErrorType);
    }

    [Fact]
    public async Task Update_marks_the_task_as_done()
    {
        var created = await _service.CreateAsync(new CreateTaskRequest("Write deploy.sh"), CancellationToken.None);

        var result = await _service.UpdateAsync(
            created.Data!.Id, new UpdateTaskRequest("Write deploy.sh", true), CancellationToken.None);

        Assert.True(result.Success);
        Assert.True(result.Data!.IsDone);
        Assert.NotNull(result.Data.UpdatedAt);
    }

    [Fact]
    public async Task Delete_removes_the_task()
    {
        var created = await _service.CreateAsync(new CreateTaskRequest("Temporary"), CancellationToken.None);

        var result = await _service.DeleteAsync(created.Data!.Id, CancellationToken.None);

        Assert.True(result.Success);
        Assert.Equal(0, await _db.Tasks.CountAsync());
    }

    [Fact]
    public async Task Delete_returns_not_found_for_a_missing_task()
    {
        var result = await _service.DeleteAsync(999, CancellationToken.None);

        Assert.False(result.Success);
        Assert.Equal(ServiceErrorType.NotFound, result.ErrorType);
    }
}
