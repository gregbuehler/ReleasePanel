using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public interface IGithubIssue
    {
        long Id { get; set; }
        string State { get; set; }
        string Title { get; set; }
        DateTime CreatedAt { get; set; }
        DateTime ClosedAt { get; set; }
        string[] Labels { get; set; }
        string[] Participants { get; set; }

        string Link { get; set; }
    }
}
