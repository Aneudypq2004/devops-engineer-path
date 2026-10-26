namespace DevOpsLab.Api.Services;

public enum ServiceErrorType
{
    Validation,
    NotFound
}

public sealed class ServiceResult<TData>
{
    public bool Success { get; private init; }
    public string? Message { get; private init; }
    public TData? Data { get; private init; }
    public ServiceErrorType? ErrorType { get; private init; }

    public static ServiceResult<TData> Ok(TData data, string? message = null) =>
        new() { Success = true, Data = data, Message = message };

    public static ServiceResult<TData> Fail(string message, ServiceErrorType errorType = ServiceErrorType.Validation) =>
        new() { Success = false, Message = message, ErrorType = errorType };
}
