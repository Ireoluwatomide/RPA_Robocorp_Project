# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
# -


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser      ${secret}[url]

*** Keywords ***
Download the excel file
    Download    https://robotsparebinindustries.com/orders.csv  overwrite=True

*** Keywords ***
Close the annoying modal
    Click Element When Visible  class:btn-dark

*** Keywords ***
Get orders
    #Table Head    orders.csv
    ${orders}=  Read table from CSV    orders.csv   header=True
    [Return]    ${orders}

*** Keywords ***
Fill the form
    [Arguments]     ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control      ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview
    sleep           2

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds     5x  0.5s    Assert order success

*** Keywords ***
Assert order success
    Click Button    class:btn-primary
    Wait Until Element Is Visible    class:alert-success

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${row}
    ${receipt_HTML}=     Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_HTML}    
    ...            ${CURDIR}${/}receipts${/}Order_${row}.pdf
    [Return]       ${CURDIR}${/}receipts${/}Order_${row}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${row}
    Capture Element Screenshot    id:robot-preview-image    
    ...                           ${CURDIR}${/}robots${/}Order_${row}.png 
    [Return]                      ${CURDIR}${/}robots${/}Order_${row}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}    ${pdf}
    Add Watermark Image To Pdf        
    ...         ${screenshot}    
    ...         ${pdf}
    ...         ${pdf}

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    
    ...     ${CURDIR}${/}receipts    
    ...     ${CURDIR}${/}output${/}Archive.zip

*** Keywords ***
Close the browser
    Close Browser    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the excel file
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close the browser

