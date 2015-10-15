Feature: Request a new xmpp password

  Background:
    Given a signed in client
    And an existing certificate and RSA key

  Scenario: [REST_01_11_01]
    Client request a new xmpp password with a valid authentication token

    When client send a PUT request to /user/1/xmpp_account with:
      | cloud_id             | ENCODED USER ID              |
      | authentication_token | AUTHENTICATION TOKEN         |
      | certificate_serial   | SERIAL_NAME                  |
      | signature            | SIGNATURE                    |

    Then the response status should be "200"
    And the JSON response should include:
      """
      ["id", "password"]
      """

  Scenario: [REST_01_11_02]
    Client request a new xmpp password with expired authentication_token

    When client send a PUT request to /user/1/xmpp_account with:
      | cloud_id             | ENCODED USER ID              |
      | authentication_token | EXPIRED AUTHENTICATION TOKEN |
      | certificate_serial   | SERIAL_NAME                  |
      | signature            | SIGNATURE                    |

    Then the response status should be "400"
    And the JSON response should include error code: "201"
    And the JSON response should include description: "Invalid cloud id or token."

  Scenario: [REST_01_11_03]
    Client request a new xmpp password with invalid signature

    When client send a PUT request to /user/1/xmpp_account with:
      | cloud_id             | ENCODED USER ID              |
      | authentication_token | AUTHENTICATION TOKEN         |
      | certificate_serial   | SERIAL_NAME                  |
      | signature            | INVALID SIGNATURE            |

    Then the response status should be "400"
    And the JSON response should include error code: "101"
    And the JSON response should include description: "Invalid signature"
