using System.Diagnostics;
using System.Reflection;
using DevOpsLab.Api.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace DevOpsLab.Api.Controllers;

/// <summary>
/// Reports which build is live, so deploy scripts can verify a release with <c>curl /api/info</c>.
/// </summary>
[ApiController]
[Route("api/info")]
public class InfoController(IHostEnvironment environment) : ControllerBase
{
    private static readonly string Version =
        typeof(InfoController).Assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
            .InformationalVersion ?? "unknown";

    private static readonly DateTimeOffset ProcessStartedAt = GetProcessStartTime();

    [HttpGet]
    public ActionResult<ApiInfoResponse> Get() =>
        Ok(new ApiInfoResponse(
            environment.ApplicationName,
            Version,
            environment.EnvironmentName,
            Environment.MachineName,
            ProcessStartedAt));

    private static DateTimeOffset GetProcessStartTime()
    {
        using var process = Process.GetCurrentProcess();
        return new DateTimeOffset(process.StartTime.ToUniversalTime(), TimeSpan.Zero);
    }
}
