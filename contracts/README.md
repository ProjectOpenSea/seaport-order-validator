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
| 8 | Consideration contains extra items |
| 9 | Private sale can not be to self |
| 10 | Protocol fee missing |
| 11 | Protocol fee item type incorrect |
| 12 | Protocol fee token incorrect |
| 13 | Protocol fee start amount too low |
| 14 | Protocol fee end amount too low |
| 15 | Protocol fee recipient incorrect |
| 16 | ERC721 amount must be one |
| 17 | ERC721 token is invalid |
| 18 | ERC721 token with identifier does not exist |
| 19 | ERC721 not owner of token |
| 20 | ERC721 conduit not approved |
| 21 | ERC1155 invalid token |
| 22 | ERC1155 conduit not approved |
| 23 | ERC1155 insufficient balance |
| 24 | ERC20 identifier must be zero |
| 25 | ERC20 invalid token |
| 26 | ERC20 insufficient allowance to conduit |
| 27 | ERC20 insufficient balance |
| 28 | Native token address must be null address |
| 29 | Native token identifier must be zero |
| 30 | Native token insufficient balance |
| 31 | Zone rejected order |
| 32 | Conduit key invalid |
| 33 | Invalid item type |
| 34 | Merkle error |
| 35 | Invalid order format. Ensure offer/consideration follow requirements |
| 36 | Signature invalid |
| 37 | Signature counter below current counter |
| 38 | Royalty fee missing |
| 39 | Royalty fee item type incorrect |
| 40 | Royalty fee token incorrect |
| 41 | Royalty fee start amount too low |
| 42 | Royalty fee end amount too low |
| 43 | Royalty fee recipient incorrect |

## Warning Codes
| Code | Warning |
| - | ----------- |
| 0 | Order expires in over 30 weeks |
| 1 | Order not active |
| 2 | Order duration less than 30 minutes |
| 3 | More than one offer item |
| 4 | Native offer item |
| 5 | Zero consideration items |
| 6 | Signature counter more than two greater than current counter |