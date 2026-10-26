using System.ComponentModel.DataAnnotations;
using DevOpsLab.Api.Domain;

namespace DevOpsLab.Api.Contracts;

public sealed record CreateTaskRequest(
    [Required, StringLength(TaskItem.TitleMaxLength, MinimumLength = 1)] string Title);

public sealed record UpdateTaskRequest(
    [Required, StringLength(TaskItem.TitleMaxLength, MinimumLength = 1)] string Title,
    bool IsDone);

public sealed record TaskResponse(
    int Id,
    string Title,
    bool IsDone,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);
