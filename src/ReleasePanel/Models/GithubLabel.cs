using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public class GithubLabel : IGithubLabel
    {
        public int Id { get; set; }
        public int Name { get; set; }
    }
}
