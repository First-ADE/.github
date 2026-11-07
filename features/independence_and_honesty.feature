Feature: Independence and honesty (axioms A8 and A9)
  As a reader of any First-ADE repository
  I want the license holder, the independence notice and the project status stated up front
  So that I know whose work this is, what I may do with it, and whether it is alive

  Scenario: A8 - LICENSE is a full MIT grant held by a named person
    Given the repository root directory
    Then the file "LICENSE" should exist
    Then the file "LICENSE" should contain "MIT License"
    Then the file "LICENSE" should contain "Copyright (c) 2026 Brandon Fox"

  Scenario: A8 - README declares independence from any employer
    Given the repository root directory
    Then the file "README.md" should contain "## Independence"
    Then the file "README.md" should contain "not affiliated with, endorsed by, or derived from the work of any employer"

  Scenario: A9 - README says what the project is and its real status
    Given the repository root directory
    Then line 1 of "README.md" should start with "# "
    Then one of the first 11 lines of "README.md" should start with "> **Status:**"

  Scenario: The principles the axioms enforce are published
    Given the repository root directory
    Then the file "PRINCIPLES.md" should exist
    Then the file "PRINCIPLES.md" should contain "## 5. Mine alone"
    Then the file "PRINCIPLES.md" should contain "## 6. Audited, then fixed"
