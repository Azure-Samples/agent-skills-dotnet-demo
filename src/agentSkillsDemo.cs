// =============================================================================
// Agent Skills Demo — Microsoft Agent Framework + Azure OpenAI
// Shows how to use FileAgentSkillsProvider to load skills from local files
//
// Usage: dotnet run src/agentSkillsDemo.cs
// =============================================================================

#:package Microsoft.Agents.AI@*-*
#:package Microsoft.Agents.AI.OpenAI@*-*
#:package Azure.AI.OpenAI@*-*
#:package Azure.Identity@*-*
#:package Microsoft.Extensions.Configuration@*-*
#:package Microsoft.Extensions.Configuration.UserSecrets@*-*

#pragma warning disable MAAI001, OPENAI001

using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Agents.AI;
using Microsoft.Extensions.Configuration;
using OpenAI.Responses;

// Step 1: Read configuration from .NET User Secrets
// Set these before running:
//   dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Endpoint" "https://YOUR.openai.azure.com/"
//   dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Deployment" "gpt-5-mini"
var config = new ConfigurationBuilder()
    .AddUserSecrets("agent-skills-demo")
    .Build();

var endpoint = config["AzureOpenAI:Endpoint"]
    ?? throw new InvalidOperationException("Set AzureOpenAI:Endpoint in User Secrets. Run: dotnet user-secrets set --id agent-skills-demo \"AzureOpenAI:Endpoint\" \"https://YOUR.openai.azure.com/\"");
var deploymentName = config["AzureOpenAI:Deployment"]
    ?? "gpt-5-mini";

// Step 2: Create the skills provider pointing to the skills directory
// FileAgentSkillsProvider reads SKILL.md files and makes them available to the agent
var skillsDir = Path.Combine(Directory.GetCurrentDirectory(), "skills");
var skillsProvider = new FileAgentSkillsProvider(skillPath: skillsDir);

// Step 3: Create the Azure OpenAI agent with skills attached
AIAgent agent = new AzureOpenAIClient(
    new Uri(endpoint), new AzureCliCredential())
    .GetResponsesClient(deploymentName)
    .AsAIAgent(new ChatClientAgentOptions
    {
        Name = "SkillsAgent",
        ChatOptions = new()
        {
            Instructions = "You are a helpful assistant with access to specialized skills.",
        },
        AIContextProviders = [skillsProvider],
    });

// Step 4: Run three prompts, one per skill, with inline sample data
Console.WriteLine("=== Agent Skills Demo ===\n");
Console.WriteLine($"Endpoint:   {endpoint}");
Console.WriteLine($"Deployment: {deploymentName}");

// --- Skill 1: Meeting Notes ---
Console.WriteLine("\n========================================");
Console.WriteLine("  SKILL 1: Meeting Notes Summarizer (Prompt)");
Console.WriteLine("========================================\n");

var meetingPrompt = """
    Summarize the key points and action items from this standup meeting transcript:

    Alice: Yesterday I finished the login page redesign. Today I'm starting on the password reset flow. No blockers.
    Bob: I've been debugging the payment timeout issue — found the root cause in the retry logic. I'll have a fix PR up by noon.
    Carol: I paired with Dave on the search API. We got pagination working. Today I'll add sorting. Blocked on the staging database credentials.
    Dave: Search API pagination is done on my end too. Today I'm writing integration tests. No blockers.
    Scrum Master: Carol, I'll get you those staging credentials within the hour. Anything else? OK, let's wrap up.
    """;

Console.WriteLine(meetingPrompt);
AgentResponse response1 = await agent.RunAsync(meetingPrompt);
Console.WriteLine("--- Response ---");
Console.WriteLine(response1.Text);

// --- Skill 2: Data Analyzer ---
Console.WriteLine("\n========================================");
Console.WriteLine("  SKILL 2: Data Analyzer (Python)");
Console.WriteLine("========================================\n");

var dataPrompt = """
    Analyze the following sales data. Identify trends, top performers, and any anomalies:

    Month,Region,Product,Units,Revenue
    Jan,North,Widget A,120,6000
    Jan,South,Widget A,95,4750
    Feb,North,Widget A,135,6750
    Feb,South,Widget A,40,2000
    Mar,North,Widget B,200,14000
    Mar,South,Widget B,180,12600
    """;

Console.WriteLine(dataPrompt);
AgentResponse response2 = await agent.RunAsync(dataPrompt);
Console.WriteLine("--- Response ---");
Console.WriteLine(response2.Text);

// --- Skill 3: Code Reviewer ---
Console.WriteLine("\n========================================");
Console.WriteLine("  SKILL 3: Code Reviewer (C#)");
Console.WriteLine("========================================\n");

var codePrompt = """
    Review the following C# code for bugs, performance issues, and best-practice violations:

    ```csharp
    public class UserService
    {
        public string GetDisplayName(string? firstName, string? lastName)
        {
            return firstName.Trim() + " " + lastName.Trim();
        }

        public async Task<List<User>> GetActiveUsersAsync(DbContext db)
        {
            var users = db.Users.ToList();
            return users.Where(u => u.IsActive).ToList();
        }
    }
    ```
    """;

Console.WriteLine(codePrompt);
AgentResponse response3 = await agent.RunAsync(codePrompt);
Console.WriteLine("--- Response ---");
Console.WriteLine(response3.Text);
