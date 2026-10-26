using DevOpsLab.Api.Data;
using DevOpsLab.Api.Data.Repositories;
using DevOpsLab.Api.Services;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Local dev: dotnet user-secrets set "ConnectionStrings:Default" "<connection string>"
// Linux server: ConnectionStrings__Default in the systemd EnvironmentFile (never in Git).
var connectionString = builder.Configuration.GetConnectionString("Default");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Connection string 'Default' is not configured. Set ConnectionStrings__Default or use dotnet user-secrets.");
}

builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<ITaskRepository, TaskRepository>();
builder.Services.AddScoped<TaskService>();

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks().AddDbContextCheck<AppDbContext>("database");

// Nginx terminates HTTP/HTTPS and forwards to Kestrel on 127.0.0.1:5000.
// Loopback proxies are trusted by default, so the real client IP and scheme come through.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
});

var app = builder.Build();

app.UseForwardedHeaders();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// No UseHttpsRedirection: TLS is handled by Nginx in front of the API.
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
