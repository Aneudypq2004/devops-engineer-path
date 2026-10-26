namespace DevOpsLab.Api.Contracts;

public sealed record ApiInfoResponse(
    string Name,
    string Version,
    string Environment,
    string Host,
    DateTimeOffset StartedAt);
