@javascript
Feature: [PCP_004_05] Package Setup
  Background:
    Given a user visit Package setup page

  Scenario: [PCP_004_05_01]
    Show synchronizing information

    When the package page will wait for connection with device
    Then the user should see "Synchronizing Package settings... " message on Package setup page

  Scenario: [PCP_004_05_02]
    Show "Device is not found" message when device was not connection

    When the package page will wait for connection with device
    And the device of Package was offline
    Then the user should see "Retry" message on Package setup page

  Scenario: [PCP_004_05_03]
    Show device information and package name list
    When the package page will wait for connection with device
    And the device was online the device will response package list
    Then the user should see package name list

  Scenario: [PCP_004_05_04]
    Show success information when update successfully

    When the package page will wait for connection with device
    And the device was online the device will response package list

    When the user changed Package setting
    And the user click "Submit" button
    And the Package services was success updated

    Then the user should see "Package settings have been successfully updated." message on Package setup page

  Scenario: [PCP_004_05_05]
    Redirect to My Devices page when user completely cancel the Package setup flow

    When the package page will wait for connection with device
    And the user click "Cancel" button
    Then the user will see the confirm message about cancel Package setup

    When the user click "Confirm" link
    Then the user will redirect to My Devices page after confirm

  Scenario: [PCP_004_05_06]
    The Package setup should continue when user click cancel but the user want to go back to setup flow

    When the package page will wait for connection with device
    And the user click "Cancel" button
    Then the user will see the confirm message about cancel Package setup

    When the user click "Cancel" button
    Then the user will go back to Package setup flow

  Scenario: [PCP_004_05_07]
    Disable any button when process of Package setting is waiting, except the cancel button

    When the package page will wait for connection with device
    And the user want to click link without cancel
    Then it should not do anything on Package setup page
