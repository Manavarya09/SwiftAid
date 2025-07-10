import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { 
  GitHubUser, 
  GitHubRepository, 
  RepositoryLanguages, 
  GitHubAPIError 
} from '../types';

export class GitHubAPI {
  private client: AxiosInstance;
  private token: string | undefined;

  constructor(token?: string) {
    this.token = token;
    this.client = axios.create({
      baseURL: 'https://api.github.com',
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'github-repo-analyzer-cli'
      }
    });

    // Add authentication header if token is provided
    if (this.token) {
      this.client.defaults.headers.common['Authorization'] = `token ${this.token}`;
    }

    // Add response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response) {
          const apiError: GitHubAPIError = {
            message: error.response.data?.message || 'GitHub API error',
            documentation_url: error.response.data?.documentation_url,
            status: error.response.status
          };
          throw apiError;
        }
        throw error;
      }
    );
  }

  /**
   * Fetch user information
   */
  async getUser(username: string): Promise<GitHubUser> {
    try {
      const response: AxiosResponse<GitHubUser> = await this.client.get(`/users/${username}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch user: ${username}`);
    }
  }

  /**
   * Fetch user's public repositories
   */
  async getUserRepositories(username: string, perPage: number = 100): Promise<GitHubRepository[]> {
    try {
      const response: AxiosResponse<GitHubRepository[]> = await this.client.get(
        `/users/${username}/repos`,
        {
          params: {
            per_page: perPage,
            sort: 'updated',
            direction: 'desc'
          }
        }
      );
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch repositories for user: ${username}`);
    }
  }

  /**
   * Fetch repository information
   */
  async getRepository(owner: string, repo: string): Promise<GitHubRepository> {
    try {
      const response: AxiosResponse<GitHubRepository> = await this.client.get(`/repos/${owner}/${repo}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch repository: ${owner}/${repo}`);
    }
  }

  /**
   * Fetch repository languages
   */
  async getRepositoryLanguages(owner: string, repo: string): Promise<RepositoryLanguages> {
    try {
      const response: AxiosResponse<RepositoryLanguages> = await this.client.get(
        `/repos/${owner}/${repo}/languages`
      );
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch languages for repository: ${owner}/${repo}`);
    }
  }

  /**
   * Fetch last commit information
   */
  async getLastCommit(owner: string, repo: string): Promise<any> {
    try {
      const response = await this.client.get(`/repos/${owner}/${repo}/commits`, {
        params: {
          per_page: 1
        }
      });
      
      if (response.data.length > 0) {
        const commit = response.data[0];
        return {
          sha: commit.sha,
          message: commit.commit.message,
          author: commit.commit.author.name,
          date: commit.commit.author.date
        };
      }
      
      return null;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch last commit for repository: ${owner}/${repo}`);
    }
  }

  /**
   * Parse repository URL to extract owner and repo name
   */
  parseRepositoryUrl(url: string): { owner: string; repo: string } | null {
    const patterns = [
      /github\.com\/([^\/]+)\/([^\/]+)/,
      /^([^\/]+)\/([^\/]+)$/
    ];

    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) {
        return {
          owner: match[1],
          repo: match[2].replace(/\.git$/, '')
        };
      }
    }

    return null;
  }

  /**
   * Check if the API token is valid
   */
  async validateToken(): Promise<boolean> {
    if (!this.token) {
      return false;
    }

    try {
      await this.client.get('/user');
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Get rate limit information
   */
  async getRateLimit(): Promise<{ limit: number; remaining: number; reset: number }> {
    try {
      const response = await this.client.get('/rate_limit');
      return response.data.rate;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch rate limit information');
    }
  }

  /**
   * Handle API errors with proper formatting
   */
  private handleError(error: any, defaultMessage: string): Error {
    if (error instanceof Error) {
      return error;
    }

    const apiError = error as GitHubAPIError;
    const message = apiError.message || defaultMessage;
    const status = apiError.status;
    
    let errorMessage = message;
    if (status) {
      errorMessage += ` (Status: ${status})`;
    }
    if (apiError.documentation_url) {
      errorMessage += `\nDocumentation: ${apiError.documentation_url}`;
    }

    return new Error(errorMessage);
  }
} 