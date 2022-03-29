# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][]

- Nothing yet

## [0.4.0][]

- Added `EctoDiff.diff/3` to allow options to be specified when performing a diff.
- Added `:overrides` as an option for diffing. This option allows specification of an alternate primary key for a specific struct in a diff. Unspecified structs will use their default primary key.

## [0.3.0][] - 2022-02-09

### Added

- Implement Access behaviour for EctoDiff structs

### Updated

- Updated dependencies
- Updated GitHub Actions

## [0.2.2][] - 2019-06-23

### Fixed

- Fix missing nil in `EctoDiff.diff/2` typespec

## [0.2.1][] - 2019-06-15

### Updated

- Updated dependencies

## [0.2.0][] - 2019-04-06

### Added

- Documentation and typespecs to all public functions
- Basic documentation and usage to the Readme
- Credo to keep code healthy
- This changelog
- MIT License
- Code coverage tracking
- Dialyzer
- .travis.yml run all the above continuously

## 0.1.0 - 2019-03-29

### Initial release

[Unreleased]: https://github.com/peek-travel/ecto_diff/compare/0.4.0...HEAD
[0.4.0]: https://github.com/peek-travel/ecto_diff/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/peek-travel/ecto_diff/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/peek-travel/ecto_diff/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/peek-travel/ecto_diff/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/peek-travel/ecto_diff/compare/0.1.0...0.2.0
