*** Settings ***
Documentation   Robot to insert all robot orders via Web UI
...             and returning archive of PDF receipts.

Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF

*** Variables ***
${URL}=         https://robotsparebinindustries.com

*** Keywords ***
Open the robot order website
    Open Available Browser      ${URL}${/}#${/}robot-order

Get orders
    Download    ${URL}${/}orders.csv    ${CURDIR}${/}temp${/}orders.csv         overwrite=${TRUE}
    ${orders}=  Read Table From CSV     ${CURDIR}${/}temp${/}orders.csv
    [Return]    ${orders}

Close the annoying modal
    Wait Until Element Is Visible       CSS:.modal
    Click Button        Yep

Fill the form
    [Arguments]        ${row}
    Select From List By Value   id:head         ${row}[Head]
    Click Element       CSS:div.stacked > div.radio input#id-body-${row}[Body]
    Input Text  //*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text  id:address    ${row}[Address]

Preview the robot
    Click Button        id:preview

Submit the order
    FOR         ${i}    IN RANGE        100
        Click Button        id:order
        Sleep   1s
        ${vis}=         Is Element Visible      id:order-another
        Exit For Loop If        ${vis}
    END

Store the receipt as a PDF file
    [Arguments]         ${order_number}
    Wait Until Element Is Visible       id:receipt
    ${receipt_html}=    Get Element Attribute   id:receipt      outerHTML
    HTML To PDF         ${receipt_html}         ${CURDIR}${/}temp${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}temp${/}${order_number}.pdf

Add screenshot of the robot to the PDF
    [Arguments]         ${order_number}
    Screenshot          id:robot-preview-image  ${CURDIR}${/}temp${/}${order_number}.png
    ${list}=    Create List     ${CURDIR}${/}temp${/}${order_number}.png
    Add Files To PDF    ${list}        ${CURDIR}${/}temp${/}${order_number}.pdf

Go to order another robot
    Click Button        id:order-another

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log     ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Store the receipt as a PDF file    ${row}[Order number]
        Add screenshot of the robot to the PDF  ${row}[Order number]
        Go to order another robot
    END
    # Create a ZIP file of the receipts
    [Teardown]  Close Browser
