using DevOpsLab.Api.Contracts;
using DevOpsLab.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace DevOpsLab.Api.Controllers;

[ApiController]
[Route("api/tasks")]
public class TasksController(TaskService taskService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TaskResponse>>> GetAll(CancellationToken cancellationToken) =>
        Ok(await taskService.GetAllAsync(cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TaskResponse>> GetById(int id, CancellationToken cancellationToken)
    {
        var result = await taskService.GetByIdAsync(id, cancellationToken);
        return result.Success ? Ok(result.Data) : ToProblem(result);
    }

    [HttpPost]
    public async Task<ActionResult<TaskResponse>> Create(CreateTaskRequest request, CancellationToken cancellationToken)
    {
        var result = await taskService.CreateAsync(request, cancellationToken);
        return result.Success
            ? CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result.Data)
            : ToProblem(result);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<TaskResponse>> Update(int id, UpdateTaskRequest request, CancellationToken cancellationToken)
    {
        var result = await taskService.UpdateAsync(id, request, cancellationToken);
        return result.Success ? Ok(result.Data) : ToProblem(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        var result = await taskService.DeleteAsync(id, cancellationToken);
        return result.Success ? NoContent() : ToProblem(result);
    }

    private ObjectResult ToProblem<TData>(ServiceResult<TData> result) =>
        Problem(
            detail: result.Message,
            statusCode: result.ErrorType == ServiceErrorType.NotFound
                ? StatusCodes.Status404NotFound
                : StatusCodes.Status400BadRequest);
}
