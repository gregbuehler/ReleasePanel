using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Dapper;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.SqlServer.Server;
using Newtonsoft.Json;
using ReleasePanel.Models;

namespace ReleasePanel.Repository
{
    public class GithubRepository : IGithubRepository
    {

        #region GithubApiObjects

        public class User
        {
            public string login { get; set; }
            public int id { get; set; }
            public string avatar_url { get; set; }
            public string gravatar_id { get; set; }
            public string url { get; set; }
            public string html_url { get; set; }
            public string followers_url { get; set; }
            public string following_url { get; set; }
            public string gists_url { get; set; }
            public string starred_url { get; set; }
            public string subscriptions_url { get; set; }
            public string organizations_url { get; set; }
            public string repos_url { get; set; }
            public string events_url { get; set; }
            public string received_events_url { get; set; }
            public string type { get; set; }
            public bool site_admin { get; set; }
        }

        public class Label
        {
            public int id { get; set; }
            public string url { get; set; }
            public string name { get; set; }
            public string color { get; set; }
            public bool @default { get; set; }
        }

        public class Assignee
        {
            public string login { get; set; }
            public int id { get; set; }
            public string avatar_url { get; set; }
            public string gravatar_id { get; set; }
            public string url { get; set; }
            public string html_url { get; set; }
            public string followers_url { get; set; }
            public string following_url { get; set; }
            public string gists_url { get; set; }
            public string starred_url { get; set; }
            public string subscriptions_url { get; set; }
            public string organizations_url { get; set; }
            public string repos_url { get; set; }
            public string events_url { get; set; }
            public string received_events_url { get; set; }
            public string type { get; set; }
            public bool site_admin { get; set; }
        }

        public class Creator
        {
            public string login { get; set; }
            public int id { get; set; }
            public string avatar_url { get; set; }
            public string gravatar_id { get; set; }
            public string url { get; set; }
            public string html_url { get; set; }
            public string followers_url { get; set; }
            public string following_url { get; set; }
            public string gists_url { get; set; }
            public string starred_url { get; set; }
            public string subscriptions_url { get; set; }
            public string organizations_url { get; set; }
            public string repos_url { get; set; }
            public string events_url { get; set; }
            public string received_events_url { get; set; }
            public string type { get; set; }
            public bool site_admin { get; set; }
        }

        public class Milestone
        {
            public string url { get; set; }
            public string html_url { get; set; }
            public string labels_url { get; set; }
            public int id { get; set; }
            public int number { get; set; }
            public string state { get; set; }
            public string title { get; set; }
            public string description { get; set; }
            public Creator creator { get; set; }
            public int open_issues { get; set; }
            public int closed_issues { get; set; }
            public string created_at { get; set; }
            public string updated_at { get; set; }
            public string closed_at { get; set; }
            public string due_on { get; set; }
        }

        public class PullRequest
        {
            public string url { get; set; }
            public string html_url { get; set; }
            public string diff_url { get; set; }
            public string patch_url { get; set; }
        }

        public class Issue
        {
            public int id { get; set; }
            public string url { get; set; }
            public string repository_url { get; set; }
            public string labels_url { get; set; }
            public string comments_url { get; set; }
            public string events_url { get; set; }
            public string html_url { get; set; }
            public int number { get; set; }
            public string state { get; set; }
            public string title { get; set; }
            public string body { get; set; }
            public User user { get; set; }
            public List<Label> labels { get; set; }
            public Assignee assignee { get; set; }
            public Milestone milestone { get; set; }
            public bool locked { get; set; }
            public int comments { get; set; }
            public PullRequest pull_request { get; set; }
            public object closed_at { get; set; }
            public string created_at { get; set; }
            public string updated_at { get; set; }
        }

        #endregion

        private SqlConnection _sqlConnection;
        private HttpClient _client;
        private string _organization;

        public GithubRepository(string connectionString, AuthenticationHeaderValue credentials, string organization)
        {
            _sqlConnection = new SqlConnection(connectionString);

            _client = new HttpClient();
            _client.DefaultRequestHeaders.Add("User-Agent", "IDS/ReleasePanel");
            _client.DefaultRequestHeaders.Add("Authorization", credentials.ToString());

            _organization = organization;
        }

        public List<GithubProject> GetProjects()
        {
            var query = @"
                            SELECT
	                            p.*,
	                            r.*,
	                            i.*
                            FROM
	                            GithubProjects p
                            INNER JOIN
	                            GithubReleases r on r.project = p.id
                            INNER JOIN
	                            GithubIssues i on i.release = r.id";

            var projectsLookup = new Dictionary<int, GithubProject>();
            var projects = _sqlConnection.Query<GithubProject, GithubRelease, GithubIssue, GithubLabel, GithubProject>(query, (p, r, i, l) =>
            {
                GithubProject project;
                if (!projectsLookup.TryGetValue(p.Id, out project))
                {
                    projectsLookup.Add(p.Id, project = p);
                }

                if (project.Releases == null)
                    project.Releases = new List<GithubRelease>();

                if (project.Releases.Count(rl => rl.Id == r.Id) == 0)
                    project.Releases.Add(r);

                var rndx = project.Releases.FindIndex(rl => rl.Id == r.Id);
                if (project.Releases[rndx].Changes == null)
                    project.Releases[rndx].Changes = new List<IGithubIssue>();

                project.Releases[rndx].Changes.Add(i);

                return project;
            });

            return projectsLookup.Values.ToList();
        }

        public GithubProject GetProject(string project)
        {
            return GetProjects().First(p => p.Name == project);

        }

        public bool Fetch(string project)
        {
            Console.WriteLine($"Attempting to retrieve data for {_organization}/{project}");

            var res = _client.GetAsync($"https://api.github.com/repos/{_organization}/{project}/issues?state=all").Result;
            if (res.IsSuccessStatusCode)
            {
                var issues = JsonConvert.DeserializeObject<List<Issue>>(res.Content.ReadAsStringAsync().Result);
                _sqlConnection.Open();
                var transaction = _sqlConnection.BeginTransaction();
                foreach (var issue in issues.Where(i => i.milestone != null))
                {
                    var releaseParams = new DynamicParameters();
                    releaseParams.Add("releaseId", issue.milestone.id);
                    releaseParams.Add("title", issue.milestone.title);
                    releaseParams.Add("createdAt", issue.milestone.created_at);
                    releaseParams.Add("closedAt", issue.milestone.closed_at);
                    releaseParams.Add("updatedAt", issue.milestone.updated_at);
                    releaseParams.Add("dueAt", issue.milestone.due_on);
                    releaseParams.Add("state", issue.milestone.state);
                    releaseParams.Add("link", issue.milestone.html_url);

                    _sqlConnection.Execute("UpsertRelease", releaseParams, transaction,
                        commandType: CommandType.StoredProcedure);

                    var issueParams = new DynamicParameters();
                    issueParams.Add("releaseId", issue.milestone.id);
                    issueParams.Add("issueId", issue.number);
                    issueParams.Add("title", issue.title);
                    issueParams.Add("createdAt", issue.created_at);
                    issueParams.Add("closedAt", issue.closed_at);
                    issueParams.Add("updatedAt", issue.updated_at);
                    issueParams.Add("body", issue.body);
                    issueParams.Add("state", issue.state);
                    issueParams.Add("link", issue.html_url);

                    _sqlConnection.Execute("UpsertIssue", issueParams, transaction,
                        commandType: CommandType.StoredProcedure);

                    var issueLabels = new List<SqlDataRecord>();
                    var metadata = new SqlMetaData[]
                    {
                        new SqlMetaData("issue", SqlDbType.BigInt),
                        new SqlMetaData("label", SqlDbType.BigInt)
                    };

                    foreach (var label in issue.labels)
                    {
                        var labelRecord = new DynamicParameters();
                        labelRecord.Add("labelId", label.id);
                        labelRecord.Add("labelName", label.name);
                        _sqlConnection.Execute("UpsertLabels", labelRecord, transaction,
                            commandType: CommandType.StoredProcedure);


                        var issueLabelRecord = new SqlDataRecord(metadata);
                        issueLabelRecord.SetInt64(0, issue.number);
                        issueLabelRecord.SetInt64(0, label.id);
                        issueLabels.Add(issueLabelRecord);
                    }
                    
                    /*
                    var issueLabelParams = new DynamicParameters();
                    issueLabelParams.Add("issueLabels", issueLabels);
                    _sqlConnection.Execute("SyncGithubIssueLabels", issueLabels, transaction,
                        commandType: CommandType.StoredProcedure);
                    */
                }
                transaction.Commit();
                _sqlConnection.Close();

                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
