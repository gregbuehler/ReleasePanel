using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public class GithubProject : IGithubProject
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Repository { get; set; }
        public string ApiKey { get; set; }
        public List<GithubRelease> Releases { get; set; }
    }
}
