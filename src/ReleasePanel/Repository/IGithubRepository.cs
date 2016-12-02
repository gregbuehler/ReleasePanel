using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ReleasePanel.Models;

namespace ReleasePanel.Repository
{
    public interface IGithubRepository
    {
        List<GithubProject> GetProjects();
        GithubProject GetProject(string project);
        bool Fetch(string project);

    }
}
