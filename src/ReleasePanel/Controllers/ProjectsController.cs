using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices.ComTypes;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ReleasePanel.Models;
using ReleasePanel.Repository;

namespace ReleasePanel.Controllers
{
    public class ProjectsController : Controller
    {
        private IGithubRepository github;

        public ProjectsController(IGithubRepository github)
        {
            this.github = github;
        }

        //[Route("")]
        public IActionResult Index()
        {
            var projects = github.GetProjects();
            ViewData["Projects"] = projects;

            return View();
        }

        [Route("projects/{project}")]
        public IActionResult Detail(string project)
        {
            var projects = github.GetProjects();
            ViewData["Project"] = projects.Find(p => p.Name == project);

            return View();
        }

        [Route("projects/{project}/{releaseId}")]
        public IActionResult Release(string project, string releaseId)
        {
            if (releaseId == "refresh")
            {
                return github.Fetch(project) ? Ok() : StatusCode(500);
            }

            try
            {
                var p = github.GetProject(project);
                var r = p.Releases.First(i => i.Id == int.Parse(releaseId));
                if (r != null)
                {
                    ViewData["Project"] = p;
                    ViewData["Release"] = r;
                }
                else
                {
                    throw new Exception($"Release {releaseId} does not exist.");
                }
            }
            catch (Exception)
            {
                return BadRequest();
            }
            
            
            
            return View();
        }
    }
}
