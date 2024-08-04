using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using CareerAdviceBackend.Models;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.IO;



namespace CareerAdviceBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RecommendationsController : ControllerBase
    {
        private readonly IChatCompletionService _chatCompletionService;
        private readonly ILogger<RecommendationsController> _logger;
        private readonly IHttpClientFactory _httpClientFactory;

        public RecommendationsController(Kernel kernel, ILogger<RecommendationsController> logger, IHttpClientFactory httpClientFactory)
        {
            _chatCompletionService = kernel.Services.GetRequiredService<IChatCompletionService>();
            _logger = logger;
            _httpClientFactory = httpClientFactory;
        }

        [HttpPost("get-recommendations")]
        public async Task<IActionResult> GetRecommendations([FromBody] UserInput userInput)
        {
       //     _logger.LogInformation("Received user input: {Skills}, {Interests}, {Experience}", userInput.Skills, userInput.Interests, userInput.Experience);

            var query = $"I have the following skills: {userInput.Skills}. " +
                        $"My interests are: {userInput.Interests}. " +
                        $"My experience includes: {userInput.Experience}. " +
                        "Based on this information, what career paths would you recommend for me?";

            var history = new ChatHistory();
            history.AddUserMessage(query);

            ChatMessageContent? result = await _chatCompletionService.GetChatMessageContentAsync(history);

            if (result == null)
            {
                _logger.LogError("Received null result from the chat completion service.");
                return StatusCode(500, "Error processing your request.");
            }

            string content = result.Content;

          //  _logger.LogInformation("Received content: {Content}", content);

            var recommendations = ParseRecommendations(content);

            _logger.LogInformation("Returning recommendations: {Count}", recommendations.Count);

            return Ok(new { recommendations });
        }
        [HttpPost("skilling-plan")]
        public async Task<IActionResult> GetSkillingPlan([FromBody] UserSelectionRequest userSelectionRequest)
        {
         //   _logger.LogInformation("Received user selection for skilling plan: {UserSelection}", userSelectionRequest.UserSelection);

            // Extract relevant details from userSelectionRequest
            var jobTitle = userSelectionRequest.UserSelection;

            var prompt = $"Given the career recommendation '{jobTitle}', generate a list of tips and advice to help someone acquire the skills and experience needed to pursue this career path.";

            var history = new ChatHistory();
            history.AddUserMessage(prompt);

            ChatMessageContent? result = await _chatCompletionService.GetChatMessageContentAsync(history);

            if (result == null)
            {
                _logger.LogError("Received null result from the chat completion service.");
                return StatusCode(500, "Error processing your request.");
            }

            string content = result.Content;

            _logger.LogInformation("Received skilling plan content: {Content}", content);

            return Ok(new { skillingPlan = content });
        }
      

        [Route("fetch-jobs")]
        public async Task<IActionResult> FetchJobs([FromBody] JobSearchRequest request)
        {
            var client = _httpClientFactory.CreateClient();
            var apiUrl = "https://linkedin-jobs-scraper-api.p.rapidapi.com/jobs"; // Replace with the actual API URL

            var payload = new
            {
                title = request.Title,
                location = request.Location,
                rows = request.Rows,
                workType = request.WorkType,
                contractType = request.ContractType,
                experienceLevel = request.ExperienceLevel,
                companyNames = request.CompanyNames,
                publishedAt = request.PublishedAt
            };

            var jsonPayload = JsonSerializer.Serialize(payload);
            var content = new StringContent(jsonPayload, System.Text.Encoding.UTF8, "application/json");

            var requestMessage = new HttpRequestMessage(HttpMethod.Post, apiUrl)
            {
                Content = content
            };
            requestMessage.Headers.Add("X-Rapidapi-Key", "xxxxxxxxxxxxxxxxxxxxxxxxx");
            requestMessage.Headers.Add("X-Rapidapi-Host", "linkedin-jobs-scraper-api.p.rapidapi.com");
            

            var response = await client.SendAsync(requestMessage);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Failed to fetch jobs from external API: {StatusCode}", response.StatusCode);
                return StatusCode((int)response.StatusCode, "Failed to fetch jobs from external API");
            }

            var jobListings = await response.Content.ReadAsStringAsync();
           // _logger.LogInformation("Received job listings: {JobListings}", jobListings); // Log the raw JSON response

            var jobs = JsonSerializer.Deserialize<List<JobListing>>(jobListings);

            return Ok(new { jobs });
        }

        private List<object> ParseRecommendations(string result)
        {
            var recommendations = new List<object>();

            var matches = Regex.Matches(result, @"\d+\.\s+([^:]+):\s+([^\.]+)\.");
            foreach (Match match in matches)
            {
                if (match.Groups.Count == 3)
                {
                    recommendations.Add(new 
                    { 
                        title = match.Groups[1].Value.Trim(), 
                        description = match.Groups[2].Value.Trim() 
                    });
                }
            }

            if (recommendations.Count == 0)
            {
                recommendations.Add(new { title = "General Advice", description = result });
            }

            return recommendations;
        }


    }
    public class CareerRecommendation
    {
        public object RecommendedJobTitle { get; internal set; }
        public string? RecommendationDescription { get; internal set; }
    }

    public class JobSearchRequest
    {
        public string Title { get; set; }
        public string Location { get; set; }
        public int Rows { get; set; }
        public string WorkType { get; set; }
        public string ContractType { get; set; }
        public string ExperienceLevel { get; set; }
        public List<string> CompanyNames { get; set; }
        public string PublishedAt { get; set; }
    }

    public class JobListing
  {
    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("publishedAt")]
    public string PublishedAt { get; set; }

    [JsonPropertyName("salary")]
    public string Salary { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; }

    [JsonPropertyName("jobUrl")]
    public string JobUrl { get; set; }

    [JsonPropertyName("companyName")]
    public string CompanyName { get; set; }

    [JsonPropertyName("companyUrl")]
    public string CompanyUrl { get; set; }

    [JsonPropertyName("location")]
    public string Location { get; set; }

    [JsonPropertyName("postedTime")]
    public string PostedTime { get; set; }

    [JsonPropertyName("applicationsCount")]
    public string ApplicationsCount { get; set; }

    [JsonPropertyName("description")]
    public string Description { get; set; }

    [JsonPropertyName("contractType")]
    public string ContractType { get; set; }

    [JsonPropertyName("experienceLevel")]
    public string ExperienceLevel { get; set; }

    [JsonPropertyName("workType")]
    public string WorkType { get; set; }

    [JsonPropertyName("sector")]
    public string Sector { get; set; }

    [JsonPropertyName("companyId")]
    public string CompanyId { get; set; }

    [JsonPropertyName("posterProfileUrl")]
    public string PosterProfileUrl { get; set; }

    [JsonPropertyName("posterFullName")]
    public string PosterFullName { get; set; }
  }
  public class UserSelectionRequest
{
    public string UserSelection { get; set; }
    
    public string Skills { get; set; }
    public string Interests { get; set; }
    public string Experience { get; set; }
}
public class SkillingPlanRequest
{
    public string UserSelection { get; set; }
    public string Skills { get; set; }
    public string Interests { get; set; }
    public string Experience { get; set; }
}

}
