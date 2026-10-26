namespace DevOpsLab.Api.Domain;

public class TaskItem
{
    public const int TitleMaxLength = 200;

    public int Id { get; set; }
    public required string Title { get; set; }
    public bool IsDone { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}
