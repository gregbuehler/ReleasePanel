using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public class GithubRelease : IGithubRelease
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ClosedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime DueAt { get; set; }
        public string State { get; set; }
        public string Link { get; set; }
        public string GithubUrl { get; set; }
        public string BuildUrl { get; set; }
        public string DeployUrl { get; set; }

        public ReleaseType ReleaseType { get; set; }
        public List<IGithubIssue> Changes { get; set; }
        public string[] Participants {
            get
            {                          
                var r = new List<string>();
                if (Changes != null)
                {
                    foreach (var change in Changes)
                    {
                        if (change.Participants == null) continue;
                        foreach (var changeParticipant in change.Participants)
                        {
                            if (!r.Contains(changeParticipant))
                            {
                                r.Add(changeParticipant);
                            }
                        }
                    }
                }
                return r.ToArray();
            }
        }
    }
}
