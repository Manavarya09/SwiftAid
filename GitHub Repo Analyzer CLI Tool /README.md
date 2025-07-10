# GitHub Repo Analyzer CLI Tool

A powerful command-line tool to analyze GitHub repositories and user profiles with beautiful, colorful output and detailed reports.

## Features

- 🔍 **Repository Analysis**: Analyze specific repositories for stars, forks, issues, languages, and more
- 👤 **User Analysis**: Analyze user profiles and their public repositories
- 📊 **Rich Statistics**: Detailed metrics including language breakdown, commit history, and engagement stats
- 🎨 **Beautiful Output**: Colorful, formatted console output with emojis and progress indicators
- 📄 **Report Generation**: Save results as JSON or Markdown files
- 🔑 **GitHub API Integration**: Full GitHub API v3 support with authentication
- ⚡ **Rate Limit Monitoring**: Check your GitHub API rate limit status
- 🛡️ **Error Handling**: Graceful error handling with informative messages

## Installation

### Prerequisites

- Node.js 16.0.0 or higher
- npm or yarn

### Install Dependencies

```bash
npm install
```

### Build the Project

```bash
npm run build
```

### Global Installation (Optional)

```bash
npm install -g .
```

## Configuration

### GitHub API Token

For better rate limits and access to private repositories (if you have access), create a GitHub Personal Access Token:

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with `public_repo` scope
3. Add it to your `.env` file:

```bash
# .env
GITHUB_TOKEN=your_github_token_here
```

Or use the `--token` option when running commands.

## Usage

### Basic Commands

```bash
# Analyze a repository
npm start repo owner/repo-name
npm start repo https://github.com/owner/repo-name

# Analyze a user
npm start user username

# Check rate limit
npm start rate-limit
```

### Command Options

```bash
# Save output to file
npm start repo owner/repo-name --output report.md
npm start user username --output user-analysis.json --format json

# Use custom token
npm start repo owner/repo-name --token your_token_here

# Specify output format
npm start repo owner/repo-name --format json
npm start user username --format md
```

### Examples

```bash
# Analyze a popular repository
npm start repo facebook/react

# Analyze a user's profile
npm start user octocat

# Save repository analysis as JSON
npm start repo microsoft/vscode --output vscode-analysis.json --format json

# Save user analysis as Markdown
npm start user torvalds --output linus-profile.md --format md
```

## Output Formats

### Console Output

The tool provides rich, colorful console output with:

- 📊 Repository statistics (stars, forks, issues)
- 💻 Language breakdown with percentages
- 🔨 Last commit information
- 👤 User profile details
- 🏆 Top repositories ranking
- 📈 Summary statistics

### File Output

#### JSON Format
Complete data structure with all analysis results:

```json
{
  "type": "repository",
  "data": {
    "repository": { ... },
    "languages": { ... },
    "lastCommit": { ... }
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

#### Markdown Format
Beautiful, formatted reports perfect for documentation:

```markdown
# Repository Analysis: facebook/react

## Repository Information
- **Name**: react
- **Description**: The library for web and native user interfaces
- **URL**: https://github.com/facebook/react
...

## Statistics
- **Stars**: ⭐ 200,000+
- **Forks**: 🍴 40,000+
- **Open Issues**: 🐛 500+

## Languages
| Language | Percentage | Bytes |
|----------|------------|-------|
| JavaScript | 65.2% | 2.1 MB |
| TypeScript | 25.1% | 800 KB |
...
```

## API Features

### Repository Analysis
- Basic repository information
- Star and fork counts
- Open issues count
- Language breakdown with percentages
- Last commit details
- Repository metadata (private, fork, archived status)

### User Analysis
- User profile information
- Public repositories list
- Total stars, forks, and issues across all repos
- Top languages used across repositories
- Top repositories by star count
- Follower and following counts

### Rate Limit Management
- Check current rate limit status
- Display usage percentage
- Show reset time
- Handle rate limit errors gracefully

## Error Handling

The tool handles various error scenarios:

- **Invalid repository format**: Clear error message with correct format examples
- **Repository not found**: Informative 404 error handling
- **User not found**: Proper error for non-existent users
- **API rate limit exceeded**: Graceful handling with retry suggestions
- **Network errors**: Connection timeout and retry logic
- **Authentication errors**: Clear guidance for token issues

## Development

### Project Structure

```
├── src/
│   ├── index.ts          # CLI entry point
│   ├── api.ts            # GitHub API client
│   └── utils.ts          # Utility functions
├── types/
│   └── index.ts          # TypeScript type definitions
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
├── .env.example          # Environment variables template
└── README.md            # This file
```

### Available Scripts

```bash
# Build the project
npm run build

# Run in development mode
npm run dev

# Clean build directory
npm run clean

# Start the CLI
npm start
```

### Adding New Features

1. **New API endpoints**: Add methods to `src/api.ts`
2. **New analysis types**: Extend types in `types/index.ts`
3. **New CLI commands**: Add to `src/index.ts`
4. **New utilities**: Add to `src/utils.ts`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

If you encounter any issues or have questions:

1. Check the error messages for guidance
2. Verify your GitHub token is valid
3. Check your rate limit status
4. Open an issue on GitHub

## Changelog

### v1.0.0
- Initial release
- Repository analysis
- User analysis
- JSON and Markdown output
- Rate limit monitoring
- Beautiful console output 