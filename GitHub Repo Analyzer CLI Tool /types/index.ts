export interface GitHubUser {
  login: string;
  id: number;
  avatar_url: string;
  html_url: string;
  name: string;
  bio: string;
  public_repos: number;
  followers: number;
  following: number;
  created_at: string;
  updated_at: string;
}

export interface GitHubRepository {
  id: number;
  name: string;
  full_name: string;
  description: string;
  html_url: string;
  stargazers_count: number;
  forks_count: number;
  open_issues_count: number;
  language: string;
  languages_url: string;
  updated_at: string;
  created_at: string;
  pushed_at: string;
  private: boolean;
  fork: boolean;
  archived: boolean;
  disabled: boolean;
  default_branch: string;
}

export interface RepositoryLanguages {
  [key: string]: number;
}

export interface RepositoryAnalysis {
  repository: GitHubRepository;
  languages: RepositoryLanguages;
  lastCommit?: {
    sha: string;
    message: string;
    author: string;
    date: string;
  };
}

export interface UserAnalysis {
  user: GitHubUser;
  repositories: GitHubRepository[];
  totalStars: number;
  totalForks: number;
  totalIssues: number;
  topLanguages: { [key: string]: number };
}

export interface AnalysisResult {
  type: 'repository' | 'user';
  data: RepositoryAnalysis | UserAnalysis;
  timestamp: string;
}

export interface CLIOptions {
  output?: string;
  format?: 'json' | 'md';
  token?: string;
}

export interface GitHubAPIError {
  message: string;
  documentation_url?: string;
  status?: number;
} 