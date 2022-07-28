# Decode Function Results
Use this file to decode validation results from `SeaportValidator`. The return value from most `SeaportValidator` functions is a `ErrorsAndWarnings` struct which contains two `uint8` arrays. First is the errors and second is the warnings. See below for the value of codes.

## Error Codes
| Code | Error |
| - | ----------- |
| 0 | End time is before start time |
| 1 | Order expired |
| 2 | Order cancelled |
| 3 | Order fully filled |
| 4 | Zero offer items |
| 5 | Offer amount must not be zero |
| 6 | Consideration amount must not be zero |
| 7 | Consideration recipient must not be null address |
| 8 | Protocol fee missing |
| 9 | Protocol fee item type incorrect |
| 10 | Protocol fee token incorrect |
| 11 | Protocol fee start amount too low |
| 12 | Protocol fee end amount too low |
| 13 | Protocol fee recipient incorrect |
| 14 | ERC721 amount must be one |
| 15 | ERC721 token is invalid |
| 16 | ERC721 token with identifier does not exist |
| 17 | ERC721 not owner of token |
| 18 | ERC721 conduit not approved |
| 19 | ERC1155 invalid token |
| 20 | ERC1155 conduit not approved |
| 21 | ERC1155 insufficient balance |
| 22 | ERC20 identifier must be zero |
| 23 | ERC20 invalid token |
| 24 | ERC20 insufficient allowance to conduit |
| 25 | ERC20 insufficient balance |
| 26 | Native token address must be null address |
| 27 | Native token identifier must be zero |
| 28 | Native token insufficient balance |
| 29 | Zone rejected order |
| 30 | Conduit key invalid |
| 31 | Invalid item type |
| 32 | Merkle error |
| 33 | Fees uncheckable due to order format. Unable to check required protocol fee. |
| 34 | Invalid Signature |

## Warning Codes
| Code | Warning |
| - | ----------- |
| 0 | Order expires in over 30 weeks |
| 1 | Order not active |
| 2 | Order duration less than 30 minutes |
| 3 | More than one offer item |
| 4 | Zero consideration items |
| 5 | More than three consideration items |
| 6 | Native offer item |
| 7 | Royalty fee missing |
| 8 | Royalty fee item type incorrect |
| 9 | Royalty fee token incorrect |
| 10 | Royalty fee start amount too low |
| 11 | Royalty fee end amount too low |
| 12 | Royalty fee recipient incorrect |
| 13 | Fees uncheckable due to order format. Protocol fee not required. |