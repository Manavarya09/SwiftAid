#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';
import { GitHubAPI } from './api';
import { Utils } from './utils';
import { 
  RepositoryAnalysis, 
  UserAnalysis, 
  AnalysisResult,
  CLIOptions 
} from '../types';

// Load environment variables
dotenv.config();

class GitHubAnalyzerCLI {
  private program: Command;
  private api: GitHubAPI;

  constructor() {
    this.program = new Command();
    this.api = new GitHubAPI(process.env.GITHUB_TOKEN);
    this.setupCommands();
  }

  private setupCommands(): void {
    this.program
      .name('github-analyzer')
      .description('Analyze GitHub repositories and user profiles')
      .version('1.0.0')
      .option('-t, --token <token>', 'GitHub API token')
      .option('-o, --output <file>', 'Output file path')
      .option('-f, --format <format>', 'Output format (json or md)', 'md');

    this.program
      .command('repo <repository>')
      .description('Analyze a specific repository')
      .action(async (repository: string, options: CLIOptions) => {
        // Merge global options with command options
        const mergedOptions = { ...this.program.opts(), ...options };
        await this.analyzeRepository(repository, mergedOptions);
      });

    this.program
      .command('user <username>')
      .description('Analyze a user\'s public repositories')
      .action(async (username: string, options: CLIOptions) => {
        // Merge global options with command options
        const mergedOptions = { ...this.program.opts(), ...options };
        await this.analyzeUser(username, mergedOptions);
      });

    this.program
      .command('rate-limit')
      .description('Check GitHub API rate limit')
      .action(async () => {
        await this.checkRateLimit();
      });
  }

  private async analyzeRepository(repository: string, options: CLIOptions): Promise<void> {
    const spinner = ora('Analyzing repository...').start();
    
    try {
      // Parse repository URL or owner/repo format
      const repoInfo = this.api.parseRepositoryUrl(repository);
      if (!repoInfo) {
        spinner.fail('Invalid repository format. Use: owner/repo or https://github.com/owner/repo');
        process.exit(1);
      }

      spinner.text = 'Fetching repository information...';
      const repo = await this.api.getRepository(repoInfo.owner, repoInfo.repo);

      spinner.text = 'Fetching language statistics...';
      const languages = await this.api.getRepositoryLanguages(repoInfo.owner, repoInfo.repo);

      spinner.text = 'Fetching last commit...';
      const lastCommit = await this.api.getLastCommit(repoInfo.owner, repoInfo.repo);

      const analysis: RepositoryAnalysis = {
        repository: repo,
        languages,
        lastCommit
      };

      const result: AnalysisResult = {
        type: 'repository',
        data: analysis,
        timestamp: new Date().toISOString()
      };

      spinner.succeed('Repository analysis completed!');
      this.displayRepositoryResults(analysis);
      await this.saveResults(result, options);

    } catch (error) {
      spinner.fail(`Analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      process.exit(1);
    }
  }

  private async analyzeUser(username: string, options: CLIOptions): Promise<void> {
    const spinner = ora('Analyzing user...').start();
    
    try {
      spinner.text = 'Fetching user information...';
      const user = await this.api.getUser(username);

      spinner.text = 'Fetching user repositories...';
      const repositories = await this.api.getUserRepositories(username);

      // Calculate statistics
      const totalStars = Utils.calculateTotalStars(repositories);
      const totalForks = Utils.calculateTotalForks(repositories);
      const totalIssues = Utils.calculateTotalIssues(repositories);
      const topLanguages = Utils.aggregateLanguages(repositories);

      const analysis: UserAnalysis = {
        user,
        repositories,
        totalStars,
        totalForks,
        totalIssues,
        topLanguages
      };

      const result: AnalysisResult = {
        type: 'user',
        data: analysis,
        timestamp: new Date().toISOString()
      };

      spinner.succeed('User analysis completed!');
      this.displayUserResults(analysis);
      await this.saveResults(result, options);

    } catch (error) {
      spinner.fail(`Analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      process.exit(1);
    }
  }

  private async checkRateLimit(): Promise<void> {
    const spinner = ora('Checking rate limit...').start();
    
    try {
      const rateLimit = await this.api.getRateLimit();
      spinner.succeed('Rate limit information retrieved!');
      
      console.log('\n' + chalk.blue.bold('GitHub API Rate Limit:'));
      console.log(chalk.gray('─'.repeat(40)));
      console.log(`Limit: ${chalk.yellow(rateLimit.limit.toLocaleString())}`);
      console.log(`Remaining: ${chalk.green(rateLimit.remaining.toLocaleString())}`);
      console.log(`Reset: ${chalk.cyan(new Date(rateLimit.reset * 1000).toLocaleString())}`);
      
      const used = rateLimit.limit - rateLimit.remaining;
      const percentage = (used / rateLimit.limit) * 100;
      console.log(`Usage: ${chalk.magenta(percentage.toFixed(1) + '%')}`);
      
    } catch (error) {
      spinner.fail(`Failed to check rate limit: ${error instanceof Error ? error.message : 'Unknown error'}`);
      process.exit(1);
    }
  }

  private displayRepositoryResults(analysis: RepositoryAnalysis): void {
    const { repository, languages, lastCommit } = analysis;
    const languageStats = Utils.sortLanguagesByPercentage(languages);

    console.log('\n' + chalk.blue.bold('📊 Repository Analysis Results'));
    console.log(chalk.gray('═'.repeat(60)));

    // Basic info
    console.log(chalk.cyan.bold('\n📁 Repository Information:'));
    console.log(`  Name: ${chalk.white(repository.full_name)}`);
    console.log(`  Description: ${chalk.gray(repository.description || 'No description')}`);
    console.log(`  URL: ${chalk.blue.underline(repository.html_url)}`);
    console.log(`  Created: ${chalk.yellow(Utils.formatDate(repository.created_at))}`);
    console.log(`  Updated: ${chalk.yellow(Utils.formatDate(repository.updated_at))}`);
    console.log(`  Private: ${repository.private ? chalk.red('Yes') : chalk.green('No')}`);
    console.log(`  Fork: ${repository.fork ? chalk.yellow('Yes') : chalk.green('No')}`);

    // Statistics
    console.log(chalk.cyan.bold('\n📈 Statistics:'));
    console.log(`  ⭐ Stars: ${chalk.yellow(repository.stargazers_count.toLocaleString())}`);
    console.log(`  🍴 Forks: ${chalk.green(repository.forks_count.toLocaleString())}`);
    console.log(`  🐛 Open Issues: ${chalk.red(repository.open_issues_count.toLocaleString())}`);

    // Languages
    if (languageStats.length > 0) {
      console.log(chalk.cyan.bold('\n💻 Languages:'));
      languageStats.slice(0, 5).forEach(({ language, percentage, bytes }) => {
        const bar = '█'.repeat(Math.floor(percentage / 5));
        console.log(`  ${chalk.white(language.padEnd(15))} ${chalk.cyan(percentage.toFixed(1) + '%')} ${chalk.gray(Utils.formatBytes(bytes))}`);
        console.log(`  ${chalk.gray(bar.padEnd(20))}`);
      });
    }

    // Last commit
    if (lastCommit) {
      console.log(chalk.cyan.bold('\n🔨 Last Commit:'));
      console.log(`  SHA: ${chalk.gray(lastCommit.sha.substring(0, 8))}`);
      console.log(`  Message: ${chalk.white(lastCommit.message)}`);
      console.log(`  Author: ${chalk.yellow(lastCommit.author)}`);
      console.log(`  Date: ${chalk.yellow(Utils.formatDate(lastCommit.date))}`);
    }

    console.log(chalk.gray('\n' + '═'.repeat(60)));
  }

  private displayUserResults(analysis: UserAnalysis): void {
    const { user, repositories, totalStars, totalForks, totalIssues, topLanguages } = analysis;

    console.log('\n' + chalk.blue.bold('👤 User Analysis Results'));
    console.log(chalk.gray('═'.repeat(60)));

    // User info
    console.log(chalk.cyan.bold('\n👤 User Information:'));
    console.log(`  Username: ${chalk.white(user.login)}`);
    console.log(`  Name: ${chalk.yellow(user.name || 'Not specified')}`);
    console.log(`  Bio: ${chalk.gray(user.bio || 'No bio')}`);
    console.log(`  Profile: ${chalk.blue.underline(user.html_url)}`);
    console.log(`  Created: ${chalk.yellow(Utils.formatDate(user.created_at))}`);

    // Summary stats
    console.log(chalk.cyan.bold('\n📊 Summary Statistics:'));
    console.log(`  📁 Total Repositories: ${chalk.white(repositories.length.toLocaleString())}`);
    console.log(`  ⭐ Total Stars: ${chalk.yellow(totalStars.toLocaleString())}`);
    console.log(`  🍴 Total Forks: ${chalk.green(totalForks.toLocaleString())}`);
    console.log(`  🐛 Total Open Issues: ${chalk.red(totalIssues.toLocaleString())}`);
    console.log(`  👥 Followers: ${chalk.cyan(user.followers.toLocaleString())}`);
    console.log(`  👤 Following: ${chalk.cyan(user.following.toLocaleString())}`);

    // Top languages
    if (Object.keys(topLanguages).length > 0) {
      console.log(chalk.cyan.bold('\n💻 Top Languages:'));
      Object.entries(topLanguages)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .forEach(([language, count]) => {
          console.log(`  ${chalk.white(language.padEnd(15))} ${chalk.cyan(count + ' repos')}`);
        });
    }

    // Top repositories
    if (repositories.length > 0) {
      console.log(chalk.cyan.bold('\n🏆 Top Repositories:'));
      repositories
        .sort((a, b) => b.stargazers_count - a.stargazers_count)
        .slice(0, 5)
        .forEach((repo, index) => {
          const medal = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][index] || '📁';
          console.log(`  ${medal} ${chalk.white(repo.name)}`);
          console.log(`     ⭐ ${chalk.yellow(repo.stargazers_count.toLocaleString())} | 🍴 ${chalk.green(repo.forks_count.toLocaleString())} | 💻 ${chalk.cyan(repo.language || 'N/A')}`);
        });
    }

    console.log(chalk.gray('\n' + '═'.repeat(60)));
  }

  private async saveResults(result: AnalysisResult, options: CLIOptions): Promise<void> {
    if (!options.output) return;

    const spinner = ora('Saving results...').start();
    
    try {
      await Utils.ensureOutputDirectory(options.output);
      
      let content: string;
      let filename: string;
      let format: 'json' | 'md';

      if (options.format === 'json') {
        content = Utils.generateJSONReport(result);
        format = 'json';
      } else {
        if (result.type === 'repository') {
          content = Utils.generateRepositoryMarkdownReport(result.data as RepositoryAnalysis);
        } else {
          content = Utils.generateUserMarkdownReport(result.data as UserAnalysis);
        }
        format = 'md';
      }

      filename = options.output || Utils.generateDefaultFilename(
        result.type, 
        result.type === 'repository' 
          ? (result.data as RepositoryAnalysis).repository.name
          : (result.data as UserAnalysis).user.login
      );

      await Utils.saveReport(content, filename, format);
      spinner.succeed(`Results saved to ${chalk.blue(filename)}`);

    } catch (error) {
      spinner.fail(`Failed to save results: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  public run(): void {
    this.program.parse();
  }
}

// Run the CLI
const cli = new GitHubAnalyzerCLI();
cli.run(); 