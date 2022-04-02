*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.FileSystem
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url} =    Input form dialog
    Open the robot order website    ${url}
    Download orders
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close browser and remove temp files

*** Keywords ***
Input form dialog
    Add heading    Launching !
    Add text input    url
    ...    label=URL website
    ...    placeholder=https://robotsparebinindustries.com/#/robot-order
    ${result}=    Run dialog
    [Return]    ${result}[url]

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Download orders
    ${URL_CSV} =    Get Secret    csv_file
    Download    ${URL_CSV}[url]    overwrite=${TRUE}

Get orders
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}

Close the annoying modal
    ${IS_MODAL}=    Is Element Visible    css:.modal-body
    IF    ${IS_MODAL} == ${TRUE}
        Click Button    css:.alert-buttons button.btn-dark
    END

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:.form-control[placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    css:#address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    ${ERROR} =    Is Element Visible    css:.alert-danger
    IF    ${ERROR} == ${TRUE}
        Submit the order
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${PDF_PATH}    Set Variable    ${CURDIR}${/}receipts${/}${orderNumber}.pdf
    Html To Pdf    ${receipt}    ${PDF_PATH}
    [Return]    ${PDF_PATH}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:robot-preview-image
    ${SCREEN_PATH}    Set Variable    ${CURDIR}${/}screenshot${/}${orderNumber}.png
    Screenshot    css:#robot-preview-image    ${SCREEN_PATH}
    [Return]    ${SCREEN_PATH}

Go to order another robot
    Click Button    id:order-another

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${orderNumber}
    ${files}=    Create List
    ...    ${screenshot}:align=center
    Add Files To PDF    ${files}    ${pdf}    ${True}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}receipts${/}    ${OUTPUT_DIR}${/}receipts.zip

Close browser and remove temp files
    Close Browser
    ${DIR_RECEIPTS_EXISTS} =    Does Directory Exist    ${CURDIR}${/}receipts${/}
    ${DIR_SCREENS_EXISTS} =    Does Directory Exist    ${CURDIR}${/}screenshot${/}
    IF    ${DIR_RECEIPTS_EXISTS} == ${TRUE}
        Remove Directory    ${CURDIR}${/}receipts${/}    True
    END
    IF    ${DIR_SCREENS_EXISTS} == ${TRUE}
        Remove Directory    ${CURDIR}${/}screenshot${/}    True
    END
    ${ORDERS_FILE_EXISTS} =    Does File Exist    ${CURDIR}${/}orders.csv
    IF    ${ORDERS_FILE_EXISTS} == ${TRUE}
        Remove File    ${CURDIR}${/}orders.csv
    END
