Feature: Shell Script Quality
  As an ADE developer
  I want all shell scripts to follow quality standards
  So that they execute reliably across environments

  Scenario: All scripts have shebangs
    Given the scripts in "scripts/" directory
    Then every ".sh" file should start with a shebang line

  Scenario: All scripts are executable
    Given the scripts in "scripts/" directory
    Then every ".sh" file should be executable in git
