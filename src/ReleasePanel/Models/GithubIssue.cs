using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public class GithubIssue : IGithubIssue
    {
        public long Id { get; set; }
        public string State { get; set; }
        public string Title { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ClosedAt { get; set; }
        public string[] Labels { get; set; }
        public string[] Participants { get; set; }

        public string Link { get; set; }
    }
}
