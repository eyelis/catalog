Feature: Catalog Lifecycle Management
  As a catalog manager
  I want to control the status of a catalog (Creation, Modification, Submission, Validation, Closure)
  In order to ensure compliance of pricing rules before their activation

  Background:
    Given that the logged-in user is a manager with code "UTXXXX"

  Scenario: Successful creation of a new catalog in Draft mode
    When I create a new catalog with the following information:
      | Type | Name                          | Default Currency |
      | Cash | Threshold Based volume/amount | EUR              |
    Then a new catalog is generated with version number "9.1"
    And the catalog status must be "DRAFT"
    And the creation date must be today
    And the unique catalog identifier "Catalog Unique Id" must be generated

  Scenario: Authorized modification of a catalog with DRAFT status
    Given an existing catalog with status "DRAFT"
    When I update the activation date with "19/05/2026"
    And I enter the description "Updated volume thresholds"
    Then the modifications are saved successfully
    And the "Last Modification Date" is updated with today
    And the modification author is recorded as "UTXXXX"

  Scenario: Failure to modify a submitted or validated catalog
    Given an existing catalog with status "SUBMITTED"
    When I attempt to modify the catalog description
    Then the system refuses the modification
    And an error message is displayed: "Catalog can only be modified in DRAFT status."

  Scenario: Submission of a catalog for validation
    Given a catalog with status "DRAFT" containing at least 1 configured product
    When I click the "Submit Catalog" button
    Then the catalog status changes to "SUBMITTED"
    And the "Submission Date" is populated with today

  Scenario: Final validation of the submitted catalog
    Given a catalog with status "SUBMITTED"
    When a validator approves the catalog
    Then the catalog status changes to "VALIDATED"
    And the "Validation Date" is recorded

  Scenario: Closure of an active catalog
    Given a catalog with status "VALIDATED"
    When I request the closure of the catalog
    Then the catalog status changes to "CLOSED"
    And the "Closure Date" is recorded

  Scenario: Deletion of a catalog with DRAFT status
    Given a catalog with status "DRAFT"
    When I click on "Delete current draft version"
    Then the catalog is permanently deleted from the system
