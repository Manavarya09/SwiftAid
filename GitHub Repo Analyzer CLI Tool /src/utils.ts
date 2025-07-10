import fs from 'fs/promises';
import path from 'path';
import { 
  RepositoryAnalysis, 
  UserAnalysis, 
  AnalysisResult,
  RepositoryLanguages,
  GitHubRepository 
} from '../types';

export class Utils {
  /**
   * Format bytes to human readable format
   */
  static formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Format date to human readable format
   */
  static formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  /**
   * Calculate total bytes from languages object
   */
  static calculateTotalBytes(languages: RepositoryLanguages): number {
    return Object.values(languages).reduce((sum, bytes) => sum + bytes, 0);
  }

  /**
   * Calculate percentage for each language
   */
  static calculateLanguagePercentages(languages: RepositoryLanguages): { [key: string]: number } {
    const total = this.calculateTotalBytes(languages);
    const percentages: { [key: string]: number } = {};

    for (const [language, bytes] of Object.entries(languages)) {
      percentages[language] = (bytes / total) * 100;
    }

    return percentages;
  }

  /**
   * Sort languages by percentage (descending)
   */
  static sortLanguagesByPercentage(languages: RepositoryLanguages): Array<{ language: string; percentage: number; bytes: number }> {
    const percentages = this.calculateLanguagePercentages(languages);
    
    return Object.entries(percentages)
      .map(([language, percentage]) => ({
        language,
        percentage,
        bytes: languages[language]
      }))
      .sort((a, b) => b.percentage - a.percentage);
  }

  /**
   * Aggregate languages across multiple repositories
   */
  static aggregateLanguages(repositories: GitHubRepository[]): { [key: string]: number } {
    const aggregated: { [key: string]: number } = {};

    repositories.forEach(repo => {
      if (repo.language) {
        aggregated[repo.language] = (aggregated[repo.language] || 0) + 1;
      }
    });

    return aggregated;
  }

  /**
   * Calculate total stars across repositories
   */
  static calculateTotalStars(repositories: GitHubRepository[]): number {
    return repositories.reduce((total, repo) => total + repo.stargazers_count, 0);
  }

  /**
   * Calculate total forks across repositories
   */
  static calculateTotalForks(repositories: GitHubRepository[]): number {
    return repositories.reduce((total, repo) => total + repo.forks_count, 0);
  }

  /**
   * Calculate total open issues across repositories
   */
  static calculateTotalIssues(repositories: GitHubRepository[]): number {
    return repositories.reduce((total, repo) => total + repo.open_issues_count, 0);
  }

  /**
   * Generate JSON report
   */
  static generateJSONReport(result: AnalysisResult): string {
    return JSON.stringify(result, null, 2);
  }

  /**
   * Generate Markdown report for repository analysis
   */
  static generateRepositoryMarkdownReport(analysis: RepositoryAnalysis): string {
    const { repository, languages, lastCommit } = analysis;
    const languageStats = this.sortLanguagesByPercentage(languages);
    
    let markdown = `# Repository Analysis: ${repository.full_name}\n\n`;
    
    // Basic repository info
    markdown += `## Repository Information\n\n`;
    markdown += `- **Name**: ${repository.name}\n`;
    markdown += `- **Description**: ${repository.description || 'No description'}\n`;
    markdown += `- **URL**: ${repository.html_url}\n`;
    markdown += `- **Created**: ${this.formatDate(repository.created_at)}\n`;
    markdown += `- **Last Updated**: ${this.formatDate(repository.updated_at)}\n`;
    markdown += `- **Default Branch**: ${repository.default_branch}\n`;
    markdown += `- **Private**: ${repository.private ? 'Yes' : 'No'}\n`;
    markdown += `- **Fork**: ${repository.fork ? 'Yes' : 'No'}\n`;
    markdown += `- **Archived**: ${repository.archived ? 'Yes' : 'No'}\n\n`;

    // Statistics
    markdown += `## Statistics\n\n`;
    markdown += `- **Stars**: ⭐ ${repository.stargazers_count.toLocaleString()}\n`;
    markdown += `- **Forks**: 🍴 ${repository.forks_count.toLocaleString()}\n`;
    markdown += `- **Open Issues**: 🐛 ${repository.open_issues_count.toLocaleString()}\n\n`;

    // Languages
    if (languageStats.length > 0) {
      markdown += `## Languages\n\n`;
      markdown += `| Language | Percentage | Bytes |\n`;
      markdown += `|----------|------------|-------|\n`;
      
      languageStats.forEach(({ language, percentage, bytes }) => {
        markdown += `| ${language} | ${percentage.toFixed(1)}% | ${this.formatBytes(bytes)} |\n`;
      });
      markdown += `\n`;
    }

    // Last commit
    if (lastCommit) {
      markdown += `## Last Commit\n\n`;
      markdown += `- **SHA**: \`${lastCommit.sha.substring(0, 8)}\`\n`;
      markdown += `- **Message**: ${lastCommit.message}\n`;
      markdown += `- **Author**: ${lastCommit.author}\n`;
      markdown += `- **Date**: ${this.formatDate(lastCommit.date)}\n\n`;
    }

    return markdown;
  }

  /**
   * Generate Markdown report for user analysis
   */
  static generateUserMarkdownReport(analysis: UserAnalysis): string {
    const { user, repositories, totalStars, totalForks, totalIssues, topLanguages } = analysis;
    
    let markdown = `# User Analysis: ${user.login}\n\n`;
    
    // User information
    markdown += `## User Information\n\n`;
    markdown += `- **Username**: ${user.login}\n`;
    markdown += `- **Name**: ${user.name || 'Not specified'}\n`;
    markdown += `- **Bio**: ${user.bio || 'No bio'}\n`;
    markdown += `- **Profile**: ${user.html_url}\n`;
    markdown += `- **Public Repos**: ${user.public_repos}\n`;
    markdown += `- **Followers**: ${user.followers.toLocaleString()}\n`;
    markdown += `- **Following**: ${user.following.toLocaleString()}\n`;
    markdown += `- **Created**: ${this.formatDate(user.created_at)}\n\n`;

    // Summary statistics
    markdown += `## Summary Statistics\n\n`;
    markdown += `- **Total Repositories**: ${repositories.length}\n`;
    markdown += `- **Total Stars**: ⭐ ${totalStars.toLocaleString()}\n`;
    markdown += `- **Total Forks**: 🍴 ${totalForks.toLocaleString()}\n`;
    markdown += `- **Total Open Issues**: 🐛 ${totalIssues.toLocaleString()}\n\n`;

    // Top languages
    if (Object.keys(topLanguages).length > 0) {
      markdown += `## Top Languages\n\n`;
      markdown += `| Language | Repository Count |\n`;
      markdown += `|----------|------------------|\n`;
      
      Object.entries(topLanguages)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 10)
        .forEach(([language, count]) => {
          markdown += `| ${language} | ${count} |\n`;
        });
      markdown += `\n`;
    }

    // Top repositories
    if (repositories.length > 0) {
      markdown += `## Top Repositories\n\n`;
      markdown += `| Repository | Stars | Forks | Language |\n`;
      markdown += `|------------|-------|-------|----------|\n`;
      
      repositories
        .sort((a, b) => b.stargazers_count - a.stargazers_count)
        .slice(0, 10)
        .forEach(repo => {
          markdown += `| [${repo.name}](${repo.html_url}) | ${repo.stargazers_count.toLocaleString()} | ${repo.forks_count.toLocaleString()} | ${repo.language || 'N/A'} |\n`;
        });
      markdown += `\n`;
    }

    return markdown;
  }

  /**
   * Save report to file
   */
  static async saveReport(content: string, filename: string, format: 'json' | 'md'): Promise<void> {
    const extension = format === 'json' ? '.json' : '.md';
    const fullPath = filename.endsWith(extension) ? filename : `${filename}${extension}`;
    
    try {
      await fs.writeFile(fullPath, content, 'utf8');
    } catch (error) {
      throw new Error(`Failed to save report to ${fullPath}: ${error}`);
    }
  }

  /**
   * Validate and create output directory if needed
   */
  static async ensureOutputDirectory(filePath: string): Promise<void> {
    const dir = path.dirname(filePath);
    if (dir !== '.') {
      try {
        await fs.mkdir(dir, { recursive: true });
      } catch (error) {
        throw new Error(`Failed to create output directory: ${error}`);
      }
    }
  }

  /**
   * Generate a default filename based on type and timestamp
   */
  static generateDefaultFilename(type: 'repository' | 'user', identifier: string): string {
    const timestamp = new Date().toISOString().split('T')[0];
    return `github-analysis-${type}-${identifier}-${timestamp}`;
  }
} 