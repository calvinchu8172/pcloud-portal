Feature: Modify Email Address

  Background:
    Given a signed in client

  Scenario: [REST_01_05_01]
    modify email account

    When client send a PUT request to /user/1/email with:
      | email                | new@ecoworkinc.com           |
      | cloud_id             | VALID_CLOUD_ID               |
      | authentication_token | VALID_AUTHENTICATION_TOKEN   |

    Then the response status should be "200"
    And the JSON response should be
      """
      {"result":"success"}
      """
    And Email deliveries should be 1

  Scenario: [REST_01_05_02]
    modify email account with wrong authentication token

    When client send a PUT request to /user/1/email with:
      | email                | new@ecoworkinc.com           |
      | cloud_id             | VALID_CLOUD_ID               |
      | authentication_token | INVALID_AUTHENTICATION_TOKEN |

    Then the response status should be "400"
    And the JSON response should include error code: "201"
    And the JSON response should include description: "Invalid cloud id or token."
    And Email deliveries should be 0

  Scenario: [REST_01_05_03]
    modify email account with the same one

    When client send a PUT request to /user/1/email with:
      | email                | THE_SAME_EMAIL               |
      | cloud_id             | VALID_CLOUD_ID               |
      | authentication_token | VALID_AUTHENTICATION_TOKEN   |

    Then the response status should be "400"
    And the JSON response should include error code: "003"
    And the JSON response should include description: "new E-mail is the same as old"
    And Email deliveries should be 0

  Scenario: [REST_01_05_04]
    modify email account with the email has been taken

    Given an existing user with:
      | id                   | taken@ecoworkinc.com         |
      | password             | taken123                     |

    When client send a PUT request to /user/1/email with:
      | email                | taken@ecoworkinc.com         |
      | cloud_id             | VALID_CLOUD_ID               |
      | authentication_token | VALID_AUTHENTICATION_TOKEN   |

    Then the response status should be "400"
    And the JSON response should include error code: "002"
    And the JSON response should include description: "new E-mail has been taken"
    And Email deliveries should be 0