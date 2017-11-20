@javascript
Feature: [PCP_003_03] Pairing

	Background:
	  Given a user choose a device
	    And the user will redirect to pairing page
	   # When debug

	Scenario: [PCP_003_03_01]
	  Show check information on first step
	   Then the user should see "Are you sure" message on pairing page

	Scenario: [PCP_003_03_02]
	  Show countdown and pairing information when pairing start
	   When the user click "Confirm" button to start pairing
		 Then the user should see the pairing information

	Scenario: [PCP_003_03_03]
	  Show "Device is not found" message when device was not connection
	   When the user click "Confirm" button to start pairing
	    But the device was not connection
	   Then the user should see "Device is not found" message on pairing page

	Scenario: [PCP_003_03_04]
	  Show timeout information
	   When the user click "Confirm" button to start pairing
		  But the user did not click on the copy button of device within 10 minutes
	   Then the user should see "Pairing has been canceled" message on pairing page

	Scenario: [PCP_003_03_05_01]
	  If the device has ddns module,
	  Show paired information and redirect to DDNS setting page when click DDNS Setting button
	   When the user click "Confirm" button to start pairing
	    And the user click the copy button of device within 10 minutes
	   Then the user should see "Successfully paired." message on pairing page
	    And the user should see "DDNS Setting" button on pairing page
	    And the user should see "My Devices" button on pairing page
	    And the user should see QR code on pairing page
	   When the user click "DDNS Setting" button when finished pairing
	   Then the user will redirect to DDNS setup page

	Scenario: [PCP_003_03_05_02]
	  If the device has ddns module,
	  Show paired information and redirect to DDNS setting page when click DDNS Setting button
	   When the device is not NAS
	   When the user click "Confirm" button to start pairing
	    And the user click the copy button of device within 10 minutes
	   Then the user should see "Successfully paired." message on pairing page
	    And the user should see "DDNS Setting" button on pairing page
	    And the user should see "My Devices" button on pairing page
	    And the user should not see QR code on pairing page
	   When the user click "DDNS Setting" button when finished pairing
	   Then the user will redirect to DDNS setup page

	Scenario: [PCP_003_03_05_03]
	  If the device doesn't have ddns module,
	  Show paired information and redirect to root page when click Device List button
	   When the device doesn't have "ddns" module
	    And the user click "Confirm" button to start pairing
	    And the user click the copy button of device within 10 minutes
	   Then the user should see "Successfully paired." message on pairing page
	    And the user should not see "DDNS Setting" button on pairing page
	    And the user should see "My Devices" button on pairing page
	    And the user should see QR code on pairing page
	   When the user click "My Devices" button when finished pairing
	   Then the user will redirect to root page

	Scenario: [PCP_003_03_06]
		Disable any button in pairing process, except the cancel button
  	 When the device was connection and pairing process is waiting
		  And the user want to click link without cancel
     Then it should not do anything on Pairing page


  Scenario: [PCP_003_03_07]
		Redirect to Search Devices page when user completely cancel the Pairing setup flow
  	 When the device was connection and pairing process is waiting
		  And the user click "Cancel" button
		 Then the user will see the confirm message about cancel Pairing flow
		 When the user click "Confirm" link
		 Then the user will redirect to Search Devices page

	Scenario: [PCP_003_03_08]
		The Pairing setup should continue when user click cancel but the user want to go back to setup flow
		 When the device was connection and pairing process is waiting
		  And the user click "Cancel" button
		 Then the user will see the confirm message about cancel Pairing flow
		 When the user click "Cancel" button
		 Then the user will go back to Pairing setup flow

	Scenario: [PCP_003_03_09]
		Show device when user unpairing the paired device
		  And the user completely pairing a device
		 When the user unpairing this device
		  And the user visits Search Devices page
		 Then the user should find the device after unpairing

	Scenario: [PCP_003_03_10]
		One device only one user can visists the pairing flow
	    But another user2 in progress paired for the same device
	   When the user click "Confirm" button to start pairing
	   Then the user will redirect to Search Devices page
	    And the user will see the error message about device is pairing

	Scenario: [PCP_003_03_11]
		The user can continuously pairing multiple devices
		  And the user completely pairing a device
		 When the user have other device
		  And the user visits Search Devices page
		 Then the user should see another devices
		 When the user click "Pairing" link to start pairing
		  And complete the pairing process
		 Then the user should see "Successfully paired." message on pairing page
