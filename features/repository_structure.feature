Feature: Repository Structure
  As an ADE developer
  I want the repository to follow standard structure conventions
  So that all contributors can navigate the project consistently

  Scenario: README exists at root
    Given the repository root directory
    Then the file "README.md" should exist

  Scenario: LICENSE exists at root
    Given the repository root directory
    Then the file "LICENSE" should exist

  Scenario: Scripts directory exists
    Given the repository root directory
    Then the directory "scripts" should exist
