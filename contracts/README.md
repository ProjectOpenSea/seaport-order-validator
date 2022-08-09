# Decode Function Results
Use this file to decode validation results from `SeaportValidator`. The return value from most `SeaportValidator` functions is a `ErrorsAndWarnings` struct which contains two `uint16` arrays. First is the errors and second is the warnings. See below for the value of codes.

## Issue Codes
| Code | Issue |
| - | ----------- |
| 100 | Invalid item type |
| 101 | Invalid order format. Ensure offer/consideration follow requirements |
| 200 | ERC20 identifier must be zero |
| 201 | ERC20 invalid token |
| 202 | ERC20 insufficient allowance to conduit |
| 203 | ERC20 insufficient balance |
| 300 | ERC721 amount must be one |
| 301 | ERC721 token is invalid |
| 302 | ERC721 token with identifier does not exist |
| 303 | ERC721 not owner of token |
| 304 | ERC721 conduit not approved |
| 400 | ERC1155 invalid token |
| 401 | ERC1155 conduit not approved |
| 402 | ERC1155 insufficient balance |
| 500 | Consideration amount must not be zero |
| 501 | Consideration recipient must not be null address |
| 502 | Consideration contains extra items |
| 503 | Private sale can not be to self |
| 504 | Zero consideration items |
| 505 | Duplicate consideration items |
| 506 | Private Sale Order. Be careful on fulfillment |
| 600 | Zero offer items |
| 601 | Offer amount must not be zero |
| 602 | More than one offer item |
| 603 | Native offer item |
| 604 | Duplicate offer item |
| 700 | Primary fee missing |
| 701 | Primary fee item type incorrect |
| 702 | Primary fee token incorrect |
| 703 | Primary fee start amount too low |
| 704 | Primary fee end amount too low |
| 705 | Primary fee recipient incorrect |
| 800 | Order cancelled |
| 801 | Order fully filled |
| 900 | End time is before start time |
| 901 | Order expired |
| 902 | Order expires in over 30 weeks |
| 903 | Order not active |
| 904 | Order duration less than 30 minutes |
| 1000 | Conduit key invalid |
| 1100 | Signature invalid |
| 1101 | Signature counter below current counter |
| 1102 | Signature counter more than two greater than current counter |
| 1103 | Signature may be invalid since `totalOriginalConsiderationItems` is not set correctly |
| 1200 | Creator fee missing |
| 1201 | Creator fee item type incorrect |
| 1202 | Creator fee token incorrect |
| 1203 | Creator fee start amount too low |
| 1204 | Creator fee end amount too low |
| 1205 | Creator fee recipient incorrect |
| 1300 | Native token address must be null address |
| 1301 | Native token identifier must be zero |
| 1302 | Native token insufficient balance |
| 1400 | Zone rejected order |
| 1500 | Merkle input only has one leaf |
| 1501 | Merkle input not sorted correctly |