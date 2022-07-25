# Decode Function Results
Use this file to decode validation results from `SeaportValidator`. The return value from most `SeaportValidator` functions is a `ErrorsAndWarnings` struct which contains two `uint8` arrays. First is the errors and second is the warnings. See below for the value of codes.

## Error Codes
| Code | Error |
| - | ----------- |
| 0 | Invalid Signature |
| 1 | End time is before start time |
| 2 | Order expired |
| 3 | Order cancelled |
| 4 | Order fully filled |
| 5 | Zero offer items |
| 6 | Protocol fee missing |
| 7 | Protocol fee item type incorrect |
| 8 | Protocol fee token incorrect |
| 9 | Protocol fee start amount too low |
| 10 | Protocol fee end amount too low |
| 11 | Protocol fee recipient incorrect |
| 12 | Consideration amount is zero |
| 13 | ERC721 amount not one |
| 14 | ERC721 token is invalid |
| 15 | ERC721 token with identifier does not exist |
| 16 | ERC1155 invalid token |
| 17 | ERC20 identifier must be zero |
| 18 | ERC20 invalid token |
| 19 | Native token address must be null address |
| 20 | Native token identifier must be zero |
| 21 | Invalid item type |
| 22 | Offer amount must not be zero |
| 23 | ERC721 not owner of token |
| 24 | ERC721 conduit not approved |
| 25 | ERC1155 conduit not approved |
| 26 | ERC20 insufficient allowance to conduit |
| 27 | ERC20 insufficient balance |
| 28 | Native insufficient balance |
| 29 | Zone rejected order |
| 30 | Conduit key invalid |
| 31 | Merkle proof error |
| 32 | Fees uncheckable due to order format. Unable to check required protocol fee. |

## Warning Codes
| Code | Warning |
| - | ----------- |
| 0 | Order expires in over 30 weeks |
| 1 | Order not active |
| 2 | Order duration less than 30 minutes |
| 3 | More than one offer item |
| 4 | Zero consideration items |
| 5 | More than four consideration items |
| 6 | Native offer item |
| 7 | Royalty fee missing |
| 8 | Royalty fee item type incorrect |
| 9 | Royalty fee token incorrect |
| 10 | Royalty fee start amount too low |
| 11 | Royalty fee end amount too low |
| 12 | Royalty fee recipient incorrect |
| 13 | Fees uncheckable due to order format |