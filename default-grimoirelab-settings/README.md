# How To Integrate Mordred Extraction to OpenSearchDashboards

This guide presumes the docker compose is successfully running.

Adapt all your credentials to the following commands.

For any interactions with Github, ensure you have made your GitHub API token available in the environment where GrimoireLabs is deployed (with `export GITHUB_API_TOKEN`), as it will be sourced into the setup.cfg for project extractions. 

## Launch Grimoire

Checklist before launching:

- credentials are configured (or default are being used)
- all API tokens for gitlab or github are set in `.env`
- all projects that need to be extracted are in projects.json under the right categories (git, github and gitlab)

For exposing the open search dashboards on a specific port, configure the nginx ports in docker compose.

Go to docker compose folder and do `docker compose up -d`. Give it some time (10-20 min), Mordred will extract all repos.

## Integrate the Dashboards (Sigils, OpenSearch) with the Data Extraction (Mordred, Sorting Hat)

Do this process after the first deployment of the GrimoireLab via docker compose.

### 1. Make / Get the data sources (index patterns)

This command is relevant for creating the index patterns for git, github and gitlab. 

- Git covers: Commits, files, authors
- Github covers: Issues, PRs, reviews, comments

```bash
curl -u admin:GrimoireLab.1 -X POST "http://localhost:5601/api/saved_objects/index-pattern" \
    -H "osd-xsrf: true" \
    -H "Content-Type: application/json" \
    -d '
    {
      "attributes": {
        "title": "github*"
      }
    }'
```

There is also a script in `dashboards-sigils` folder which can be run with `./make_index_patterns.sh` which makes such patterns for git, github and gitlab. Be sure to adapt the credentials.

### 2. Make the SIGIL dashboards

```bash
curl -u admin:GrimoireLab.1 -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "osd-xsrf:true" \
  --form file=@git.ndjson
```

[All SIGIL dashboards can be found here](https://github.com/chaoss/grimoirelab-sigils/tree/main/panels/json/opensearch_dashboards).

There is also a script in `dashboards-sigils` which can be run with `./upload_sigils_to_opensearch.sh` and uploads all dashboards relevant to git, github and gitlab (downloaded from the link above). Careful to adapt any changed credentials, the default ones are in the script.

### 3. Custom Bug Fixes

#### A. Dashboards

If there are issues in the GitHub PR and Issues dashboards with fields like Submitters then the following bug fix is necessary. Follow these community recommendations: the fix is the following: https://github.com/chaoss/grimoirelab-sigils/issues/517

#### B. Aliases

If any of the aliases are missing in dashboards with a message such as `Opensearch index does not exist: INDEX`, you can create it with the following command (either cli or in Dev Tools in the dashboard).

```bash
POST /_aliases
{
  "actions": [
    {
      "add": {
        "index": "github_enriched",
        "alias": "github_issues"
      }
    }
  ]
}
```

## Updating projects

1. Edit the `projects.json` file. 
2. Restart the mordred container with `docker compose restart mordred`
3. Remember to `Refresh` the Dashboard

For automatic updating. There is a script in `dashboards-sigils` which can be run with `./intake_new_projects.sh`. 

You can then create a cronjob for it with `crontab -e` and setting `*/5 * * * * /open-pulse/open-pulse-grimoirelab//dashboards-sigils/intake_new_projects.sh >> /open-pulse/open-pulse-grimoirelab//cron_logs/intake_new_projects.log 2>&1`. (Note: replace paths with your paths from root)

## Utils for debugging

### List data sources / index patterns

Sanity check. It can also be seen on OpenSearch UI under Dashboard Management - Index patterns.

```bash
curl -u admin:GrimoireLab.1 -X GET "http://localhost:5601/api/saved_objects/_find?type=index-pattern" \
  -H "osd-xsrf: true"
```

### Check the indexes and aliases

This allows to confirm the Mordred extraction went well for all your projects in projects.json. You can also confirm by seeing `collection finished` in the Mordred docker logs. 

It can also be seen on OpenSearch UI under Index Management - Indexes.

```bash
curl -k -u admin:GrimoireLab.1 -X GET "https://localhost:9200/_cat/indices?s=i"
```

```bash
curl -k -u admin:GrimoireLab.1 -X GET "https://localhost:9200/_cat/aliases?v"
```

(ignore check of certificates with `-k`)

### Get the dashboards

It can also be seen on OpenSearch UI under Dashbaords Management - Saved Objects.

```bash
curl -u admin:GrimoireLab.1 -X GET "http://localhost:5601/api/saved_objects/_find?type=dashboard" \   
  -H "osd-xsrf: true"
```
