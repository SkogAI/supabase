#!/usr/bin/env bash

set -e
# @env WORKTREE_BASE=/home/skogix/dev/supabase/.dev/worktree
# @env PARSE_TEMPLATE=/home/skogix/dev/supabase/.github/sparse-checkouts/default.txt
# @meta symbol @config
# @meta require-tools git

# @cmd do yadda to branch
# @arg branch![`_available_branches`] Branch to whatever
branch() {
  echo "$argc_branch"
}

# {{ gh issue
# @cmd Manage issues
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @flag --help    Show help for command
issue() {
  gh issue
}

# {{{ gh issue create
# @cmd Create a new issue
# @option -a --assignee*,[`_choice_assignee`] <login>  Assign people by their login.
# @option -b --body <string>                      Supply a body.
# @option -F --body-file <file>                   Read body text from file (use "-" to read from standard input)
# @flag -e --editor                               Skip prompts and open the text editor to write the title and body in.
# @option -l --label*,[`_choice_label`] <name>    Add labels by name
# @option -m --milestone[`_choice_milestone`] <name>  Add the issue to a milestone by name
# @option -p --project[`_choice_repo_project`] <title>  Add the issue to projects by title
# @option --recover <string>                      Recover input from a failed run of create
# @option -T --template[`_choice_issue_template`] <name>  Template name to use as starting body text
# @option -t --title <string>                     Supply a title.
# @flag -w --web                                  Open the browser to create an issue
# @flag --help                                    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
issue::create() {
  gh issue create
}
# }}} gh issue create

# {{{ gh issue list
# @cmd List issues in a repository
# @option --app <string>                           Filter by GitHub App author
# @option -a --assignee*,[`_choice_assignee`] <string>  Filter by assignee
# @option -A --author[`_choice_search_user`] <string>  Filter by author
# @option -q --jq <expression>                     Filter JSON output using a jq expression
# @option --json*,[`_choice_issue_field`] <fields>  Output JSON with the specified fields
# @option -l --label*,[`_choice_label`] <string>   Filter by label
# @option -L --limit <int>                         Maximum number of issues to fetch (default 30)
# @option --mention[`_choice_mention`] <string>    Filter by mention
# @option -m --milestone[`_choice_milestone`] <string>  Filter by milestone number or title
# @option -S --search <query>                      Search issues with query
# @option -s --state[open|closed|all] <string>     Filter by state:  (default "open")
# @option -t --template[`_choice_issue_template`] <string>  Format JSON output using a Go template; see "gh help formatting"
# @flag -w --web                                   List issues in the web browser
# @flag --help                                     Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
issue::list() {
  gh issue list
}
# }}} gh issue list

# {{{ gh issue status
# @cmd Show status of relevant issues
# @option -q --jq <expression>    Filter JSON output using a jq expression
# @option --json*,[`_choice_issue_field`] <fields>  Output JSON with the specified fields
# @option -t --template[`_choice_issue_template`] <string>  Format JSON output using a Go template; see "gh help formatting"
# @flag --help                    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
issue::status() {
  gh issue status
}
# }}} gh issue status

# {{{ gh issue close
# @cmd Close issue
# @option -c --comment <string>    Leave a closing comment
# @option -r --reason <string>     Reason for closing: {completed|not planned}
# @flag --help                     Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_open_issue`]
issue::close() {
  gh issue close
}
# }}} gh issue close

# {{{ gh issue comment
# @cmd Add a comment to an issue
# @option -b --body <text>         The comment body text
# @option -F --body-file <file>    Read body text from file (use "-" to read from standard input)
# @flag --create-if-none           Create a new comment if no comments are found.
# @flag --delete-last              Delete the last comment of the current user
# @flag --edit-last                Edit the last comment of the current user
# @flag -e --editor                Skip prompts and open the text editor to write the body in
# @flag -w --web                   Open the web browser to write the comment
# @flag --yes                      Skip the delete confirmation prompt when --delete-last is provided
# @flag --help                     Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_open_issue`]
issue::comment() {
  gh issue comment
}
# }}} gh issue comment

# {{{ gh issue delete
# @cmd Delete issue
# @flag --yes     Confirm deletion without prompting
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_all_issue`]
issue::delete() {
  gh issue delete
}
# }}} gh issue delete

# {{{ gh issue develop
# @cmd Manage linked branches for an issue
# @option -b --base[`_choice_branch`] <string>    Name of the remote branch you want to make your new branch from
# @option --branch-repo <string>                  Name or URL of the repository where you want to create your new branch
# @flag -c --checkout                             Checkout the branch after creating it
# @flag -l --list                                 List linked branches for the issue
# @option -n --name[`_choice_branch`] <string>    Name of the branch to create
# @flag --help                                    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_open_issue`]
issue::develop() {
  gh issue develop
}
# }}} gh issue develop

# {{{ gh issue edit
# @cmd Edit issues
# @option --add-assignee*,[`_choice_assignee`] <login>  Add assigned users by their login.
# @option --add-label*,[`_choice_label`] <name>    Add labels by name
# @option --add-project*,[`_choice_repo_project`] <title>  Add the issue to projects by title
# @option -b --body <string>                       Set the new body.
# @option -F --body-file <file>                    Read body text from file (use "-" to read from standard input)
# @option -m --milestone[`_choice_milestone`] <name>  Edit the milestone the issue belongs to by name
# @option --remove-assignee*,[`_choice_issue_assignee`] <login>  Remove assigned users by their login.
# @option --remove-label*,[`_choice_issue_label`] <name>  Remove labels by name
# @flag --remove-milestone                         Remove the milestone association from the issue
# @option --remove-project*,[`_choice_issue_project`] <title>  Remove the issue from projects by title
# @option -t --title <string>                      Set the new title.
# @flag --help                                     Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_open_issue`]
issue::edit() {
  gh issue edit
}
# }}} gh issue edit

# {{{ gh issue lock
# @cmd Lock issue conversation
# @option -r --reason[off_topic|resolved|spam|too_heated] <string>  Optional reason for locking conversation.
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_all_issue`]
issue::lock() {
  gh issue lock
}
# }}} gh issue lock

# {{{ gh issue pin
# @cmd Pin a issue
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_open_issue`]
issue::pin() {
  gh issue pin
}
# }}} gh issue pin

# {{{ gh issue reopen
# @cmd Reopen issue
# @option -c --comment <string>    Add a reopening comment
# @flag --help                     Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_closed_issue`]
issue::reopen() {
  gh issue reopen
}
# }}} gh issue reopen

# {{{ gh issue transfer
# @cmd Transfer issue to another repository
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_all_issue`]
# @arg destination-repo![`_choice_search_repo`]
issue::transfer() {
  gh issue transfer
}
# }}} gh issue transfer

# {{{ gh issue unlock
# @cmd Unlock issue conversation
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_all_issue`]
issue::unlock() {
  gh issue unlock
}
# }}} gh issue unlock

# {{{ gh issue unpin
# @cmd Unpin a issue
# @flag --help    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue[`_choice_pin_issue`]
issue::unpin() {
  gh issue unpin
}
# }}} gh issue unpin

# {{{ gh issue view
# @cmd View an issue
# @flag -c --comments             View issue comments
# @option -q --jq <expression>    Filter JSON output using a jq expression
# @option --json*,[`_choice_issue_field`] <fields>  Output JSON with the specified fields
# @option -t --template[`_choice_issue_template`] <string>  Format JSON output using a Go template; see "gh help formatting"
# @flag -w --web                  Open an issue in the browser
# @flag --help                    Show help for command
# @option -R --repo[`_choice_search_repo`] <[HOST/]OWNER/REPO>  Select another repository using the [HOST/]OWNER/REPO format
# @arg issue![`_choice_issue_number`]
issue::view() {
  gh issue view "$argc_issue"
}
# }}} gh issue view
# }} gh issue

# {{ claude
# @cmd Manage Claude CLI
claude() {
  :;
}

# {{ claude mcp
# @cmd Manage Claude MCP servers
claude::mcp() {
  :
}

# {{{ claude mcp list
# @cmd List configured MCP servers
claude::mcp::list() {
  /home/skogix/.claude/local/claude mcp list
}
# }}} claude mcp list

# {{{ claude mcp add
# @cmd Add an MCP server
# @arg name!  Server name
# @arg command!  Command to run the server
claude::mcp::add() {
  /home/skogix/.claude/local/claude mcp add "$argc_name" "$argc_command"
}
# }}} claude mcp add

# {{{ claude mcp remove
# @cmd Remove an MCP server
# @arg name![`_choice_list_mcp`]  Server name to remove
claude::mcp::remove() {
  /home/skogix/.claude/local/claude mcp remove "$argc_name"
}
# }}} claude mcp remove

# {{{ claude mcp get
# @cmd Get details about an MCP server
# @arg name![`_choice_list_mcp`]  Server name
claude::mcp::get() {
  /home/skogix/.claude/local/claude mcp get "$argc_name"
}
# }}} claude mcp get
# }} claude mcp
# }} claude

_available_issues() {
  gh issue list --json number --jq '.[].number'
}

_available_branches() {
  git branch
}

_choice_issue_number() {
  gh issue list --json number --jq '.[].number'
}

_choice_list_mcp() {
  /home/skogix/.claude/local/claude mcp list 2>/dev/null | tail -n +3 | awk -F': ' '{print $1}'
}

# @cmd skogix2 test
skogix2() {
  if [[ -n "$argc_config" ]]; then
    echo "Loading config from: $argc_config"
    if [[ -f "$argc_config" ]]; then
      # echo "Contents:"
      # cat "$argc_config"
      source $argc_config
      echo $ABC
    else
      echo "Error: File not found!"
    fi
  else
    echo "No config file specified"
  fi
}

# @cmd skogix test
# @arg name!  Name of the new worktree
skogix() {
  # Step 1: Build the worktree path
  local WORKTREE_PATH="${WORKTREE_BASE}/${argc_name}"
  # Step 2: Create worktree and the last part of the path as branch
  git worktree add "$WORKTREE_PATH"
  # Step 3: Change into the worktree
  cd "$WORKTREE_PATH"
  # Step 4: Enable sparse-checkout mode
  git sparse-checkout init --no-cone
  # Step 5: Apply sparse-checkout rules (PARSE_TEMPLATE must be absolute path)
  git sparse-checkout set --no-cone --stdin <"$PARSE_TEMPLATE"
  # Step 6: Re-read the working tree to apply sparse-checkout
  git checkout
}

# @cmd Create GitHub issue with @claude mention
# @arg description!  Issue title/description
create-issue() {
  scripts/claude-issue "$argc_description"
}

# @cmd Add @claude comment to existing issue
# @arg issue_number!  Issue number
# @arg task!          Task description
on-issue() {
  scripts/claude-on-issue "$argc_issue_number" "$argc_task"
}

# @cmd Create PR from current branch with @claude mention
# @arg description!  Task description for Claude
pr() {
  scripts/claude-pr "$argc_description"
}

# @cmd Add @claude comment to existing PR
# @arg pr_number!  PR number
# @arg task!       Task description
on-pr() {
  scripts/claude-on-pr "$argc_pr_number" "$argc_task"
}

# @cmd View Claude activity status
status() {
  scripts/claude-status
}

# @cmd Smart wrapper: creates issue OR PR based on git state
# @arg description!  Task description
quick() {
  scripts/claude-quick "$argc_description"
}

# @cmd Auto-create PR for current Claude branch
auto-pr() {
  scripts/auto-create-pr
}

# @cmd Sync all claude/* branches with main/master
sync() {
  scripts/claude-sync
}

# @cmd Delete merged claude/* branches locally and remotely
cleanup() {
  scripts/claude-cleanup
}

# @cmd Monitor workflow runs with real-time updates
# @option --logs  Follow job logs after completion
# @option --compact  Use compact output mode
# @arg run_id  Specific workflow run ID to watch
watch() {
  local args=()
  if [ -n "${argc_logs:-}" ]; then
    args+=("--logs")
  fi
  if [ -n "${argc_compact:-}" ]; then
    args+=("--compact")
  fi
  if [ -n "${argc_run_id:-}" ]; then
    args+=("$argc_run_id")
  fi
  scripts/claude-watch "${args[@]}"
}

# @cmd Run linting and testing checks
lint-and-test() {
  scripts/lint-and-test
}

# @cmd Check PR mergeability and call @claude to resolve
check-mergeable() {
  scripts/check-mergeable
}

. "$ARGC_COMPLETIONS_ROOT/utils/_argc_utils.sh"

_choice_hostname() {
  host_yml_path="$(_argc_util_path_resolve CONFIG_DIR gh/hosts.yml)"
  if [[ ! -f "$host_yml_path" ]]; then
    return
  fi
  cat "$host_yml_path" | yq 'keys | .[]'
}

_choice_auth_scope() {
  cat <<-'EOF'
repo	Grants full access to private and public repositories.
repo:status	Grants read/write access to public and private repository commit statuses.
repo_deployment	Grants access to deployment statuses for public and private repositories.
public_repo	Limits access to public repositories.
repo:invite	Grants accept/decline abilities for invitations to collaborate on a repository.
security_events	Grants read and write access to security events in the code scanning API.
admin:repo_hook	Grants read, write, ping, and delete access to repository hooks in public and private repositories.
read:repo_hook	Grants read and ping access to hooks in public or private repositories.
write:repo_hook	Grants read, write, and ping access to hooks in public or private repositories.
admin:org	Fully manage the organization and its teams, projects, and memberships.
write:org	Read and write access to organization membership, organization projects, and team membership.
read:org	Read-only access to organization membership, organization projects, and team membership.
admin:public_key	Fully manage public keys.
write:public_key	Create, list, and view details for public keys.
read:public_key	List and view details for public keys.
admin:org_hook	Grants read, write, ping, and delete access to organization hooks.
gist	Grants write access to gists.
notifications	Grants read access to a user's notifications
user	Grants read/write access to profile info only.
read:user	Grants access to read a user's profile data.
user:email	Grants read access to a user's email addresses.
user:follow	Grants access to follow or unfollow other users.
project	Grants read/write access to user and organization projects.
read:project	Grants read only access to user and organization projects.
delete_repo	Grants access to delete adminable repositories.
write:packages	Grants access to upload or publish a package in GitHub Packages.
read:packages	Grants access to download or install packages from GitHub Packages.
delete:packages	Grants access to delete packages from GitHub Packages.
admin:gpg_key	Fully manage GPG keys.
write:gpg_key	Create, list, and view details for GPG keys.
read:gpg_key	List and view details for GPG keys.
codespace	Full control of codespaces
workflow	Grants the ability to add and update GitHub Actions workflow files.
EOF
}

_choice_branch() {
  _helper_repo_query 'refs(first: 100, refPrefix: "refs/heads/") { nodes { name, target { abbreviatedOid } } }' |
    yq '.data.repository.refs.nodes[] | .name + "	" + .target.abbreviatedOid'
}

_choice_search_repo() {
  _argc_util_mode_kv /
  if [[ -z "$argc__kv_prefix" ]]; then
    _choice_owner | _argc_util_transform suffix=/ nospace
  else
    _helper_search_repo "$argc__kv_key" "$argc__kv_filter"
  fi
}

_choice_codespace() {
  gh codespace list --json name,owner,repository,state |
    yq '.[] | .name + "	" + .owner + " • " + .repository + " • " + .state'
}

_choice_owner() {
  _argc_util_parallel _choice_search_user ::: _choice_search_org
}

_choice_org() {
  gh api user/orgs | yq '.[] | .login + "	" + (.description // "")'
}

_choice_search_user() {
  val=${1:-$ARGC_CWORD}
  if [[ "${#val}" -lt 2 ]]; then
    return
  fi
  gh api graphql -f query='
        query {
            search( type:USER, query: "'$val' in:login", first: 100) {
                edges { node { ... on User { login name } } } 
            }
        }' |
    yq '.data.search.edges[].node | .login + "	" + (.name // "")'
}

_choice_codespace_field() {
  gh codespace list --json 2>&1 | tail -n +2
}

_choice_gist() {
  _helper_user_query 'gists(first:100, privacy:ALL, orderBy: {field: UPDATED_AT, direction: DESC}) { edges { node { name, description } } } ' |
    yq '.data.user.gists.edges[].node | .name + "	" + (.description // "")'
}

_choice_gist_file() {
  _helper_user_query 'gist(name:"'$argc_gist'") { files { name } }' |
    yq '.data.user.gist.files[].name'
}

_choice_assignee() {
  _helper_repo_query 'assignableUsers(first: 100, query: "'$ARGC_CWORD'") { nodes { login, name } }' |
    yq '.data.repository.assignableUsers.nodes[] | .login + "	" + (.name // "")'
}

_choice_label() {
  _helper_repo_query 'labels(first: 100) { nodes { name, description } }' |
    yq '.data.repository.labels.nodes[] | .name + "	" + (.description // "")'
}

_choice_milestone() {
  _helper_repo_query 'milestones(first: 100, states: OPEN) { nodes { title, description } }' |
    yq '.data.repository.milestones.nodes[] | .title + "	" + (.description // "")'
}

_choice_repo_project() {
  _helper_repo_query 'projectsV2(first: 100, orderBy: {direction: DESC, field: UPDATED_AT}) { nodes {  number title } }' |
    yq '.data.repository.projectsV2.nodes[] | .number + "	" + .title'
}

_choice_issue_template() {
  _helper_repo_query 'issueTemplates { name, about }' |
    yq '.data.repository.issueTemplates[] | .name + "	" + (.about // "")'
}

_choice_issue_field() {
  gh issue list --json 2>&1 | tail -n +2
}

_choice_mention() {
  _helper_repo_query 'mentionableUsers(first: 100, query: "'$ARGC_CWORD'") { nodes { login, name } }' |
    yq '.data.repository.mentionableUsers.nodes[] | .login + "	" + (.name // "")'
}

_choice_open_issue() {
  _helper_query_issue OPEN
}

_choice_all_issue() {
  _helper_query_issue
}

_choice_issue_assignee() {
  if [[ -z "$argc_issue" ]]; then
    return
  fi
  _helper_repo_query 'issue(number: '$argc_issue') { assignees(first: 100) { nodes { login, name } } }' |
    yq '.data.repository.issue.assignees.nodes[]| .login + "	" + (.name // "")'
}

_choice_issue_label() {
  if [[ -z "$argc_issue" ]]; then
    return
  fi
  _helper_repo_query 'issue(number: '$argc_issue') { labels(first: 100) { nodes { name, description } } }' |
    yq '.data.repository.issue.labels.nodes[] | .name + "	" + (.description // "")'
}

_choice_issue_project() {
  if [[ -z "$argc_issue" ]]; then
    return
  fi
  _helper_repo_query 'issue(number: '$argc_issue') { projectsV2(first:100) { nodes { number title } } }' |
    yq '.data.repository.issue.projectsV2.nodes[] | .number + "	" + .title'
}

_choice_closed_issue() {
  _helper_query_issue CLOSED
}

_choice_pin_issue() {
  _helper_repo_query 'pinnedIssues(first: 3) { nodes { issue { number, title, state } } }' |
    yq '.data.repository.pinnedIssues.nodes[].issue | .number + "	" + .title'
}

_choice_pr_field() {
  gh pr list --json 2>&1 | tail -n +2
}

_choice_open_pr() {
  _helper_query_pr OPEN
}

_choice_pr_checks() {
  _argc_util_parallel _choice_branch ::: _choice_open_pr
}

_choice_pr_assignee() {
  if [[ -z "$argc_pr" ]]; then
    return
  fi
  _helper_repo_query 'pullRequest(number: '$argc_pr') { assignees(first: 100) { nodes { login, name } } }' |
    yq '.data.repository.pullRequest.assignees.nodes[] | .login + "	" + (.name // "")'
}

_choice_pr_label() {
  if [[ -z "$argc_pr" ]]; then
    return
  fi
  _helper_repo_query 'pullRequest(number: '$argc_pr') { labels(first: 100) { nodes { name, description } } }' |
    yq '.data.repository.pullRequest.labels.nodes[] | .name + "	" + (.description // "")'
}

_choice_pr_project() {
  if [[ -z "$argc_pr" ]]; then
    return
  fi
  _helper_repo_query 'pullRequest(number: '$argc_pr') { projectsV2(first:100) { nodes { number title } } }' |
    yq '.data.repository.pullRequest.projectsV2.nodes[] | .number + "	" + .title'
}

_choice_pr_reviewer() {
  if [[ -z "$argc_pr" ]]; then
    return
  fi
  _helper_repo_query 'pullRequest(number: '$argc_pr') { latestReviews(first:100) { nodes { author { login } } } }' |
    yq '.data.repository.pullRequest.latestReviews.nodes[].author.login'
}

_choice_pr_commit() {
  if [[ -z "$argc_pr" ]]; then
    return
  fi
  _helper_repo_curl pulls/$argc_pr/commits |
    yq '.[] | .sha + "	" + .commit.message'
}

_choice_ready_pr() {
  _helper_repo_query 'pullRequests(first: 100, states: OPEN, orderBy: {direction: DESC, field: UPDATED_AT}) { nodes {  number, title, isDraft, state  } }' |
    yq '.data.repository.pullRequests.nodes[] | select(.isDraft) | .number + "	" + .title'
}

_choice_closed_pr() {
  _helper_query_pr CLOSED
}

_choice_project() {
  if [[ -n "$argc_owner" ]]; then
    gh api graphql -f query='query { organization(login: "'$argc_owner'") { projectsV2(first: 100) { nodes { number title } } } }' |
      yq '.data.organization.projectsV2.nodes[] | .number + "	" + .title'
  else
    user_val="$(_helper_get_user)"
    if [[ -n "$user_val" ]]; then
      gh api graphql -f query='query { user(login: "'$user_val'") { projectsV2(first: 100) { nodes { number title } } } }' |
        yq '.data.user.projectsV2.nodes[] | .number + "	" + .title'
    fi
  fi
}

_choice_discussion_category() {
  _helper_repo_query 'discussionCategories(first:100) { nodes { name, description } } ' |
    yq '.data.repository.discussionCategories.nodes[] | .name + "	" + (.description // "")'

}

_choice_tag() {
  _helper_repo_query 'refs(first: 100, refPrefix: "refs/tags/", orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) { nodes { name } }' |
    yq '.data.repository.refs.nodes[] | .name'
}

_choice_release_asset() {
  if [[ -z $argc_tag ]]; then
    return
  fi
  _helper_repo_query 'release(tagName: "'$argc_tag'") { releaseAssets(first:100) { nodes { name } } }' |
    yq '.data.repository.release.releaseAssets.nodes[].name'
}

_choice_gitignore() {
  gh api gitignore/templates | yq '.[]'
}

_choice_license() {
  gh api licenses | yq '.[] | .key + "	" + .name'
}

_choice_repo_field() {
  gh repo list --json 2>&1 | tail -n +2
}

_choice_repo_key() {
  _helper_repo_curl keys | yq '.[] | .id + "	" + .title'
}

_choice_search_topic() {
  if [[ "${#ARGC_CWORD}" -lt 2 ]]; then
    return
  fi
  gh api "search/topics?per_page=100&q=$ARGC_CWORD" | yq '.items[] | .name + "	" + (.short_description // "")'
}

_choice_repo_topic() {
  _helper_repo_query 'repositoryTopics(first:100) { nodes { topic { name } } }' |
    yq '.data.repository.repositoryTopics.nodes[].topic.name'
}

_choice_inprogress_run() {
  _helper_repo_curl 'actions/runs?status=in_progress' |
    yq '.workflow_runs[] | .id + "	" + .name + ": " + (.display_title // "")'
}

_choice_all_run() {
  _helper_repo_curl 'actions/runs' |
    yq '.workflow_runs[] | .id + "	" + .name + ": " + (.display_title // "")'
}

_choice_artifact_name() {
  local path
  if [[ -z "$argc_run_id" ]]; then
    path="actions/artifacts"
  else
    path="actions/runs/$argc_run_id/artifacts"
  fi
  _helper_repo_curl "$path" |
    yq '.artifacts[].name'
}

_choice_workflow_event() {
  cat <<-'EOF'
branch_protection_rule
check_run
check_suite
create
delete
deployment
deployment_status
discussion
discussion_comment
fork
gollum
issue_comment
issues
label
merge_group
milestone
page_build
project
project_card
project_column
public
pull_request
pull_request_review
pull_request_review_comment
pull_request_target
push
registry_package
release
repository_dispatch
schedule
status
watch
workflow_call
workflow_dispatch
workflow_run
EOF
}

_choice_run_field() {
  gh run list --json 2>&1 | tail -n +2
}

_choice_workflow() {
  _helper_repo_curl "actions/workflows" |
    yq '.workflows[] | .id + "	" + .name'
}

_choice_run_job() {
  if [[ -z "$argc_run_id" ]]; then
    return
  fi
  _helper_repo_curl "actions/runs/$argc_run_id/jobs" |
    yq '.jobs[] | .id + "	" + .name'
}

_choice_failed_run() {
  _helper_repo_curl 'actions/runs?status=failure' |
    yq '.workflow_runs[] | .id + "	" + .name + ": " + (.display_title // "")'
}

_choice_workflow_or_file() {
  if _argc_util_is_path "$ARGC_CWORD"; then
    _argc_util_comp_path
  else
    _choice_workflow
  fi
}

_choice_alias() {
  gh alias list | sed 's/:/\t/'
}

_choice_config_key() {
  config_yml_path="$(_argc_util_path_resolve CONFIG_DIR gh/config.yml)"
  if [[ ! -f "$config_yml_path" ]]; then
    return
  fi
  cat "$config_yml_path" | yq 'keys | .[]'
}

_choice_gpg_key() {
  gh api user/gpg_keys |
    yq '.[] | .key_id + "	" + .name'
}

_choice_ruleset() {
  gh ruleset list $(_argc_util_param_select_options --repo) |
    _argc_util_transform_table 'ID;NAME' '\t'
}

_choice_commit_field() {
  gh search commits --json 2>&1 | tail -n +2
}

_choice_secret() {
  gh secret list
}

_choice_ssh_key() {
  gh api user/keys |
    yq '.[] | .id + "	" + .title'
}

_choice_env() {
  _helper_repo_curl 'environments' |
    yq '.environments[].name'
}

_choice_search_org() {
  val=${1:-$ARGC_CWORD}
  if [[ "${#val}" -lt 2 ]]; then
    return
  fi
  gh api graphql -f query='
        query {
            search( type:USER, query: "'$val' in:login", first: 100) {
                edges { node { ... on Organization  { login name } } } 
            }
        }' |
    yq '.data.search.edges[].node | .login + "	" + (.name // "")'
}

_choice_variable() {
  if [[ -n "$argc_org" ]]; then
    gh "orgs/$argc_org/actions/variables?per_page=100" |
      yq '.variables[] | .name + "	" + .value'
  else
    _helper_repo_curl 'actions/variables?per_page=100' |
      yq '.variables[] | .name + "	" + .value'
  fi
}

_helper_get_user() {
  host_yml_path="$(_argc_util_path_resolve CONFIG_DIR gh/hosts.yml)"
  if [[ ! -f "$host_yml_path" ]]; then
    return
  fi
  cat "$host_yml_path" | yq 'to_entries | .[0].value.user'
}

_helper_query_issue() {
  local states
  if [[ -n "$1" ]]; then
    states="states: $1,"
  fi
  _helper_repo_query 'issues(first: 100, '"$states"' orderBy: {direction: DESC, field: UPDATED_AT}) { nodes { number, title, state } }' |
    yq '.data.repository.issues.nodes[] | .number + "	" + .title'
}

_helper_query_pr() {
  local states
  if [[ -n "$1" ]]; then
    states="states: $1,"
  fi
  _helper_repo_query 'pullRequests(first: 100, '"$states"' orderBy: {direction: DESC, field: UPDATED_AT}) { nodes {  number, title, isDraft, state  } }' |
    yq '.data.repository.pullRequests.nodes[] | .number + "	" + .title'
}

_helper_repo_curl() {
  _helper_retrieve_owner_repo_vals
  if [[ -z "$owner_val" ]] || [[ -z "$repo_val" ]]; then
    return
  fi
  gh api "repos/$owner_val/$repo_val/$1"
}

_helper_repo_query() {
  _helper_retrieve_owner_repo_vals
  if [[ -z "$owner_val" ]] || [[ -z "$repo_val" ]]; then
    return
  fi
  gh api graphql -f query='query { repository(owner: "'$owner_val'", name: "'$repo_val'") { '"$1"' } }'
}

_helper_retrieve_owner_repo_vals() {
  if [[ "$argc_repo" == *'/'* ]]; then
    owner_val="${argc_repo%/*}"
    repo_val="${argc_repo##*/}"
  else
    local raw_values="$(
      git remote -v |
        gawk '{
                if (match($0, /^origin\thttps:\/\/[^\/]+\/([^\/]+)\/([^\/]+) \(fetch\)/, arr)) {
                    gsub(".git", "", arr[2])
                    print arr[1] " " arr[2]
                } else if (match($0, /^origin\t[^:]+:([^\/]+)\/([^\/]+) \(fetch\)/, arr)) {
                    gsub(".git", "", arr[2])
                    print arr[1] " " arr[2]
                }
            }'
    )"
    local values=($raw_values)
    if [[ "${#values[@]}" -eq 2 ]]; then
      owner_val=${values[0]}
      repo_val=${values[1]}
    fi
  fi
}

_helper_search_repo() {
  gh api graphql -f query='
        query {
            search( type:REPOSITORY, query: """user:'$1' "'$2'" in:name fork:true""", first: 100) {
                edges { node { ... on Repository { name description } } } 
            }
        }' |
    yq '.data.search.edges[].node | .name + "	" + (.description // "")'
}

_helper_user_query() {
  user_val="$(_helper_get_user)"
  if [[ -z "$user_val" ]]; then
    return
  fi
  gh api graphql -f query='query { user(login: "'$user_val'") { '"$1"' } }'
}

_module_os_command() {
  if _argc_util_has_path_prefix; then
    _argc_util_comp_path
    return
  fi
  if [[ "$ARGC_OS" == "windows" ]]; then
    PATH="$(echo "$PATH" | sed 's|:[^:]*/windows/system32:|:|Ig')" compgen -c
  else
    compgen -c
  fi
}

eval "$(argc --argc-eval "$0" "$@")"
