Feature: [Console_02_03] Create APP API

  Background:
   Given an user exists
     And an existing certificate and RSA key

  Scenario: [Console_02_03_01]
    Create app successfully with create_db = 1

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "200"
     And the JSON response should be:
      | code    | 0000 |
      | message | OK   |
     And the JSON response should have new app info

  Scenario: [Console_02_03_02]
    Create app successfully with create_db = 0

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 0                                  |
    Then the response status should be "200"
     And the JSON response should be:
      | code    | 0000 |
      | message | OK   |
     And the JSON response should have new app info

  Scenario: [Console_02_03_03]
    Fail to create app without timestamp

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      # | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.37"
     And the JSON response should include error message: "Missing Required Header: X-Timestamp"

  Scenario: [Console_02_03_04]
    Fail to create app with invalid timestamp

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | INVALID TIMESTAMP                  |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.38"
     And the JSON response should include error message: "Invalid timestamp"

  Scenario: [Console_02_03_05]
    Fail to create app without signature in Header

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      # | signature            | VALID SIGNATURE                    |
      | timestamp            | INVALID TIMESTAMP                  |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.0"
     And the JSON response should include error message: "Missing Required Header: X-Signature"

  Scenario: [Console_02_03_06]
    Fail to create app with invalid signature in Header

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | INVALID SIGNATURE                  |
      | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.1"
     And the JSON response should include error message: "Invalid signature"

  Scenario: [Console_02_03_07]
    Fail to create app without certificate serial

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      # | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.2"
     And the JSON response should include error message: "Missing Required Parameter: certificate_serial"

  Scenario: [Console_02_03_08]
    Fail to get app list with invalid certificate serial

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | INVALID CERTIFICATE SERIAL         |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | VALID TIMESTAMP                    |
      | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.3"
     And the JSON response should include error message: "Invalid certificate_serial"

  Scenario: [Console_02_03_09]
    Fail to create app without name

   Given Dynamo_DB will successfully create table
    When client send a POST request to /v1/oauth2/applications with:
      | certificate_serial   | VALID CERTIFICATE SERIAL           |
      | signature            | VALID SIGNATURE                    |
      | timestamp            | VALID TIMESTAMP                    |
      # | name                 | VALID NAME                         |
      | scopes               | VALID SCOPES                       |
      | redirect_uri         | VALID REDIRECT_URI                 |
      | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
      | create_table         | 1                                  |
    Then the response status should be "400"
     And the JSON response should include error code: "400.39"
     And the JSON response should include error message: "Missing Required Parameter: name"

  # Scenario: [Console_02_03_10]
  #   Fail to create app list without redirect uri

  #  Given Dynamo_DB will successfully create table
  #   When client send a POST request to /v1/oauth2/applications with:
  #     | certificate_serial   | VALID CERTIFICATE SERIAL           |
  #     | signature            | VALID SIGNATURE                    |
  #     | timestamp            | VALID TIMESTAMP                    |
  #     | name                 | VALID NAME                         |
  #     | scopes               | VALID SCOPES                       |
  #     # | redirect_uri         | VALID REDIRECT_URI                 |
  #     | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
  #     | create_table         | 1                                  |
  #   Then the response status should be "400"
  #    And the JSON response should include error code: "400.40"
  #    And the JSON response should include error message: "Missing Required Parameter: redirect_uri"

  # Scenario: [Console_02_03_11]
  #   Fail to create app list without create_table

  #  Given Dynamo_DB will successfully create table
  #   When client send a POST request to /v1/oauth2/applications with:
  #     | certificate_serial   | VALID CERTIFICATE SERIAL           |
  #     | signature            | VALID SIGNATURE                    |
  #     | timestamp            | VALID TIMESTAMP                    |
  #     | name                 | VALID NAME                         |
  #     | scopes               | VALID SCOPES                       |
  #     | redirect_uri         | VALID REDIRECT_URI                 |
  #     | logout_redirect_uri  | VALID LOGOUT_REDIRECT_URI          |
  #     # | create_table         | 1                                  |
  #   Then the response status should be "400"
  #    And the JSON response should include error code: "400.41"
  #    And the JSON response should include error message: "Missing Required Parameter: create_table"
