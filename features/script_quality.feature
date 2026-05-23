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

  Scenario: Every shell script has a matching PowerShell script
    Given the scripts in "scripts/" directory
    Then every ".sh" file should have a corresponding ".ps1" script

  Scenario: Every PowerShell script has a matching shell script
    Given the scripts in "scripts/" directory
    Then every ".ps1" file should have a corresponding ".sh" script
