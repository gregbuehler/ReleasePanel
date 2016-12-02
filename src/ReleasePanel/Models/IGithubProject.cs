using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public interface IGithubProject
    {
        int Id { get; set; }
        string Name { get; set; }
        string Repository { get; set; }
        string ApiKey { get; set; }

        List<GithubRelease> Releases { get; set; }
    }
}
