# ReleasePanel

ReleasePanel is an attempt to provide a control panel that utilizes Github Milestones as releases and captures semantic metadata via labels.

## Quickstart

```
git clone git@github.com/gregbuehler/ReleasePanel.git
cd ./ReleasePanel/src/ReleasePanel

// edit appsettings.json or create appsettings.env.json

dotnet restore
dotnet run

// populate or update a project
curl http://localhost:5000/projects/{project}/refresh
```

## TODO

* Add a better landing page that isn't the ASPNET default
* Properly retrieve labels when fetching via GithubRepository
* Figure out a way to associate with CI and CD systems
* Make things look awesome
* Add a scheduler system or other way to consistently update data
* Add the concept of reports