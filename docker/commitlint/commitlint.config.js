/**
 * Commit convention — Conventional Commits.
 * Expected format:  type(scope): subject
 *   e.g. feat(auth): add password reset
 *        fix(api): handle empty response
 *
 * The scope is optional. A ticket reference (e.g. PROJ-123) can be used as scope.
 */
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Allowed types — aligned with the groups handled by git-cliff (see cliff.toml)
    'type-enum': [
      2,
      'always',
      [
        'feat', // new feature
        'fix', // bug fix
        'perf', // performance improvement
        'refactor', // refactoring without behavior change
        'docs', // documentation
        'style', // formatting, no code impact
        'test', // add/update tests
        'build', // build system, dependencies
        'ci', // CI/CD pipelines
        'chore', // miscellaneous maintenance
        'revert', // revert a commit
      ],
    ],
    'subject-case': [0], // subject case is not enforced
    'body-max-line-length': [0], // no strict limit on the body
  },
};
