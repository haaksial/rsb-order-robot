*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.5s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close pop-up
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        #    Go to order another robot
    END
    # Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    #set this url in local vault

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True    #set this url in local vault
    ${orders}=    Read table from CSV    orders.csv    headers:True
    [Return]    ${orders}

Close pop-up
    Click Button    OK    #get rid of the pop-up by clicking ok

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]    #Select correct head
    Select Radio Button    body    id-body-${row}[Body]    #Select correct body
    Input Text    //input[@type="number"]    ${row}[Legs]    #Type shipping address
    Input Text    address    ${row}[Address]    #Type shipping address

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Page Should Contain    Receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    Wait Until Element Is Visible    receipt
    ${receipt}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    [Return]    ${screenshot}=    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}order_preview_${Order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${screenshot}
    Save Pdf    ${pdf}
    Close Pdf
