using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using System.IO;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddHttpClient();
builder.Services.AddLogging();

// Add CORS policy
var allowedOrigins = Environment.GetEnvironmentVariable("ALLOWED_ORIGINS")?.Split(',');
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowSpecificOrigin",
        builder => builder.WithOrigins(allowedOrigins)
                          .AllowAnyHeader()
                          .AllowAnyMethod()
                          .AllowCredentials());
});

// Configure Semantic Kernel
builder.Services.AddSingleton<Kernel>(serviceProvider =>
{
    var kernelBuilder = Kernel.CreateBuilder();
    kernelBuilder.AddAzureOpenAIChatCompletion(
        deploymentName: "gpt4",
        modelId: "gpt-4",
        endpoint: Environment.GetEnvironmentVariable("OPENAI_API_ENDPOINT") ?? throw new InvalidOperationException("OPENAI_API_ENDPOINT is not set."),
        apiKey: Environment.GetEnvironmentVariable("OPENAI_API_KEY") ?? throw new InvalidOperationException("OPENAI_API_KEY is not set.")
    );

    return kernelBuilder.Build();
});

// Configure Kestrel to use the certificate and listen on specified ports
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    var pfxPath = Path.Combine(Directory.GetCurrentDirectory(), "advicebackend.pfx");
    var pfxPassword = Environment.GetEnvironmentVariable("PFX_PASSWORD");

    serverOptions.ListenAnyIP(80); // HTTP
    serverOptions.ListenAnyIP(443, listenOptions =>
    {
        listenOptions.UseHttps(pfxPath, pfxPassword);
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    //app.UseHttpsRedirection(); // Only redirect to HTTPS in production
    app.UseHsts(); // Add HSTS to enforce HTTPS in production
}

app.UseCors("AllowSpecificOrigin"); // Enable CORS with the specific policy
app.UseAuthorization();
app.MapControllers();

app.Run();
