# Smart Pipeline Pseudo-Code

```
on push or pull_request:
  changed_files = git diff between base commit and head commit

  if changed_files is exactly ["CHANGELOG.md"]:
    print "No Terraform changes"
    exit success

  affected_apps = empty set

  for each file in changed_files:
    if file starts with "global/iam/":
      affected_apps.add("apps/payment-api")
      affected_apps.add("apps/user-api")

    if file starts with "apps/payment-api/":
      affected_apps.add("apps/payment-api")

    if file starts with "apps/user-api/":
      affected_apps.add("apps/user-api")

  if affected_apps is empty:
    print "No affected Terraform stacks"
    exit success

  for each app in affected_apps as a matrix job:
    cd into app
    terraform init
    terraform plan > plan.txt
    append plan.txt to GitHub Actions Step Summary
```