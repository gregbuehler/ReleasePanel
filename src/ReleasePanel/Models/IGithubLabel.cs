using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReleasePanel.Models
{
    public interface IGithubLabel
    {
        int Id { get; set; }
        int Name { get; set; }
    }
}
