# Liquibase Pipeline

## Required tooling

- [liquibase](https://www.liquibase.org)
- [consul-template](https://github.com/hashicorp/consul-template)

## General Operation

The pipeline operates along these lines.

1. Database repository is checked out into `db/` folder
2. Liquibase configuration created using consul-template
3. Liquibase commands run
4. Magic!
5. Database updated

