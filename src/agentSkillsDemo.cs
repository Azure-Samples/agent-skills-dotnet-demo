// =============================================================================
// Agent Skills Demo — Microsoft Agent Framework + Azure OpenAI
// Shows how to use FileAgentSkillsProvider to load skills from local files
//
// Usage: dotnet run src/agentSkillsDemo.cs
// =============================================================================

#:package Microsoft.Agents.AI@1.0.0
#:package Microsoft.Agents.AI.OpenAI@1.0.0
#:package Azure.AI.OpenAI@2.8.0-beta.1
#:package Azure.Identity@1.20.0
#:package Microsoft.Extensions.Configuration@10.0.5
#:package Microsoft.Extensions.Configuration.UserSecrets@10.0.5

// MAAI001: Microsoft.Agents.AI marks some APIs as experimental during the 1.0 stabilization period.
// OPENAI001: Azure.AI.OpenAI 2.8.0-beta.1 is pre-release; its APIs are subject to change.
// Both pragmas are required until GA releases remove the [Experimental] attributes.
#pragma warning disable MAAI001, OPENAI001

using System.Diagnostics;
using Azure;
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

// ── Pre-flight validation ──────────────────────────────────────────────────
Console.WriteLine("=== Pre-flight Checks ===\n");

// Check that skills directory exists
var skillsDir = Path.Combine(Directory.GetCurrentDirectory(), "skills");
if (Directory.Exists(skillsDir))
{
    var skillCount = Directory.GetDirectories(skillsDir).Length;
    Console.WriteLine($"✅ Skills directory found: {skillsDir} ({skillCount} skill(s))");
}
else
{
    Console.WriteLine($"❌ Skills directory not found: {skillsDir}");
    Console.WriteLine("   Make sure you run this from the repository root.");
    return;
}

// Verify User Secrets are configured (endpoint was loaded above)
Console.WriteLine($"✅ Azure OpenAI endpoint configured");
Console.WriteLine($"✅ Deployment: {deploymentName}");

// Check Python availability (needed for data-analyzer skill)
try
{
    var psi = new ProcessStartInfo
    {
        FileName = "python",
        Arguments = "--version",
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true,
    };
    using var proc = Process.Start(psi);
    if (proc is not null)
    {
        var version = (await proc.StandardOutput.ReadToEndAsync()).Trim();
        if (string.IsNullOrEmpty(version))
            version = (await proc.StandardError.ReadToEndAsync()).Trim();
        await proc.WaitForExitAsync();
        Console.WriteLine($"✅ Python available: {version}");
    }
}
catch
{
    Console.WriteLine("⚠️  Python not found. The data-analyzer skill requires Python.");
    Console.WriteLine("   Install Python from https://python.org or add it to PATH.");
}

Console.WriteLine();

// Step 2: Create the skills provider pointing to the skills directory
// AgentSkillsProvider reads SKILL.md files and makes them available to the agent
var skillsProvider = new AgentSkillsProvider(skillsDir);

// Step 3: Create the Azure OpenAI agent with skills attached
// DefaultAzureCredential tries, in order: managed identity, Azure CLI, interactive browser,
// environment variables — so this works in dev, CI, and production without code changes.
AIAgent agent = new AzureOpenAIClient(
    new Uri(endpoint), new DefaultAzureCredential())
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
try
{
    AgentResponse response1 = await agent.RunAsync(meetingPrompt);
    Console.WriteLine("--- Response ---");
    Console.WriteLine(response1.Text);
}
catch (RequestFailedException ex)
{
    Console.WriteLine($"❌ Azure API error: {ex.Message}");
    Console.WriteLine("   Check your endpoint URL, deployment name, and RBAC permissions.");
    Console.WriteLine("   Run: az role assignment list --assignee <your-id> --scope <resource-id>");
}
catch (OperationCanceledException)
{
    Console.WriteLine("❌ Request timed out. The Azure OpenAI service may be under heavy load.");
    Console.WriteLine("   Try again in a few seconds.");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Unexpected error: {ex.Message}");
}

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
try
{
    AgentResponse response2 = await agent.RunAsync(dataPrompt);
    Console.WriteLine("--- Response ---");
    Console.WriteLine(response2.Text);
}
catch (RequestFailedException ex)
{
    Console.WriteLine($"❌ Azure API error: {ex.Message}");
    Console.WriteLine("   Possible rate limiting or authentication issue.");
    Console.WriteLine("   Check: az account show (correct subscription?)");
}
catch (OperationCanceledException)
{
    Console.WriteLine("❌ Request timed out. The Azure OpenAI service may be under heavy load.");
    Console.WriteLine("   Try again in a few seconds.");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Unexpected error: {ex.Message}");
}

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
try
{
    AgentResponse response3 = await agent.RunAsync(codePrompt);
    Console.WriteLine("--- Response ---");
    Console.WriteLine(response3.Text);
}
catch (RequestFailedException ex)
{
    Console.WriteLine($"❌ Azure API error: {ex.Message}");
    Console.WriteLine("   If 429 (rate limit): wait and retry, or check your quota.");
    Console.WriteLine("   If 401/403: re-authenticate with: az login");
}
catch (OperationCanceledException)
{
    Console.WriteLine("❌ Request timed out. The Azure OpenAI service may be under heavy load.");
    Console.WriteLine("   Try again in a few seconds.");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Unexpected error: {ex.Message}");
}
