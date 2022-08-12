[![Test CI][ci-badge]][ci-link]
[![Code Coverage][coverage-badge]][coverage-link]

# Seaport Order Validator

Seaport Order Validator provides a solidity contract which validates orders and components via RPC static calls. There are a variety of functions which conduct micro and macro validations on various components of the order. Each validation function returns two arrays of uint16s, the first is an array of errors, and the second is an array of warnings. For a quick lookup of issue codes, see the [issue table](contracts/README.md). For detailed documentation on the requirements to pass validation, see the [notion doc](https://opensea.notion.site/Seaport-Order-Validation-ac2b521251de49369bef2bd9de1585af).

[ci-badge]: https://github.com/ProjectOpenSea/seaport-order-validator/actions/workflows/test.yml/badge.svg
[ci-link]: https://github.com/ProjectOpenSea/seaport-order-validator/actions/workflows/test.yml
[coverage-badge]: https://coveralls.io/repos/github/ProjectOpenSea/seaport-order-validator/badge.svg?branch=main&t=UvcQpQ
[coverage-link]: https://coveralls.io/github/ProjectOpenSea/seaport-order-validator?branch=main