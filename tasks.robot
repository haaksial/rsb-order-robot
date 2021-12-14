*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               csv can be downloaded from: https://robotsparebinindustries.com/orders.csv
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.5s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${download_url}=    Ask orders URL from user
    Open the robot order website
    ${orders}=    Get orders    ${download_url}
    FOR    ${row}    IN    @{orders}
        Close pop-up
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close browser

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    urls
    Log    ${secret}[orderpage]
    Open Available Browser    ${secret}[orderpage]

Get orders
    [Arguments]    ${download_url}
    Download    ${download_url}    overwrite=True
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
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    temp${/}order_nro_${Order number}.pdf
    [Return]    temp${/}order_nro_${Order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}order_preview.png
    [Return]    ${OUTPUT_DIR}${/}order_preview.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    append:True
    Close Pdf    ${pdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zipfile}=    Set Variable    ${OUTPUT_DIR}/receipt_archive.zip
    Archive Folder With Zip    ${CURDIR}${/}/temp    ${zipfile}

Ask orders URL from user
    Add text input    url    label=orders.csv location    placeholder=Enter URL where to download orders.csv
    ${result}=    Run dialog
    [Return]    ${result.url}
