# Project Structure

```
agent-skills-dotnet-demo/
├── README.md                  # Quick start (3 steps)
├── LICENSE                    # MIT License
├── setup.ps1                  # Automated setup script
├── azure.yaml                 # azd project configuration
├── docs/                      # Detailed documentation
│   ├── setup-guide.md         # Full setup & troubleshooting
│   ├── skills-reference.md    # Skills deep dive
│   └── project-structure.md   # This file
├── src/                       # Source code
│   └── agentSkillsDemo.cs    # Main demo (file-based .NET app)
├── skills/                    # Agent Skills (3 demos)
│   ├── meeting-notes/         # Prompt-only skill
│   │   └── SKILL.md
│   ├── code-reviewer/         # .NET script skill
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── analyze.csx
│   └── data-analyzer/         # Python script skill
│       ├── SKILL.md
│       └── scripts/
│           └── analyze.py
└── infra/                     # Azure Bicep deployment
    ├── main.bicep
    ├── main.parameters.json
    └── modules/
        ├── cognitive-services.bicep
        └── model-deployment.bicep
```
