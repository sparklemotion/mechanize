---
name: update-user-agents
description: Update the browser User-Agent strings in Mechanize::AGENT_ALIASES (lib/mechanize.rb) to the latest versions by running examples/latest_user_agents.rb, then open a pull request. Use when asked to "update user agents", "refresh AGENT_ALIASES", or bump the browser versions mechanize pretends to be.
---

# Update user agents

`Mechanize::AGENT_ALIASES` in `lib/mechanize.rb` holds the User-Agent strings that `Mechanize#user_agent_alias=` selects. The modern-browser entries go stale as browsers release. `examples/latest_user_agents.rb` fetches the current strings from WhatIsMyBrowser.com and prints them as a Hash with the same keys as `AGENT_ALIASES`. This skill runs that script and copies the result into the constant.

## Which aliases to update

Only the aliases the script prints are updated:

`Linux Firefox`, `Mac Firefox`, `Mac Safari`, `Windows Chrome`, `Windows Edge`, `Windows Firefox`, `Android`, `iPhone`, `iPad`

Leave every other alias as it is. `Mechanize`, `Windows IE *`, `* Mozilla`, `Linux Konqueror` and `Mac Safari 4` deliberately name old or fixed versions, and users depend on them staying put.

## Steps

1. Work in your fork of `sparklemotion/mechanize`. Bring the fork's `main` up to date with upstream, then create a topic branch from it.

   ```sh
   gh repo sync <your GitHub login>/mechanize
   git fetch origin
   git switch -c update-user-agent-aliases origin/main
   ```

2. Run the script from the repository root.

   ```sh
   bundle exec ruby -Ilib examples/latest_user_agents.rb
   ```

   It makes four requests with a one-second pause between them. Do not loop it or shorten the pause.

3. Check the output before touching `lib/mechanize.rb`.
   - All nine keys have a non-empty value that starts with `Mozilla/5.0`.
   - No version goes backwards compared with the current `AGENT_ALIASES`.

   An empty string or an exception means the page markup changed. Fix the CSS selectors in `examples/latest_user_agents.rb` and run it again. Never type a User-Agent string by hand, because the script is the record of where each value came from.

4. Replace the nine values in `AGENT_ALIASES`. Keep the key order, quoting style, and blank-line grouping of the existing constant, so the diff shows only the version changes.

5. Run the tests.

   ```sh
   bundle exec rake test
   ```

6. Push the branch to your fork and open a pull request from it to `sparklemotion/mechanize` `main`.

   ```sh
   git push -u origin update-user-agent-aliases
   gh pr create -R sparklemotion/mechanize --base main --head <your GitHub login>:update-user-agent-aliases
   ```

   - Title: `Update User-Agent strings for agent aliases`
   - Body: one sentence on what changed, then the command and its full output in a code block, as in #632. Reviewers compare the diff against that output.
   - If the script itself needed a fix, put it in a separate commit and say why in the body.

7. Add an entry to `CHANGELOG.md`, as #612 did, and push it to the same branch. The entry needs the PR number, so this comes after the PR is opened. Put it under `## next / unreleased` at the top, and create that section if it is missing.

   ```markdown
   * Updated User-Agent strings to represent modern browser versions. (#<PR number>) @<your GitHub login>
   ```
