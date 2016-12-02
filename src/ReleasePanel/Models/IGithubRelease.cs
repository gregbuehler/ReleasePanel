using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public interface IGithubRelease
    {
        int Id { get; set; }
        string Title { get; set; }
        DateTime CreatedAt { get; set; }
        DateTime ClosedAt { get; set; }
        DateTime UpdatedAt { get; set; }
        DateTime DueAt { get; set; }
        string State { get; set; }
        string Link { get; set; }
        string BuildUrl { get; set; }
        string DeployUrl { get; set; }

        ReleaseType ReleaseType { get; set; }

        List<IGithubIssue> Changes { get; set; }

        string[] Participants { get; }
    }

    public enum ReleaseType
    {
        Unknown,
        Scheduled,
        Hotfix
    }
}
