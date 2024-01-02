# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][]

- Nothing yet

## [0.5.1][]

- Implement diffing for has_many through associations, resolves associated error.

## [0.5.0][]

### Added

- Include virtual fields in the EctoDiff struct by default. This might be a breaking change for a very small number of users. [#150](https://github.com/peek-travel/ecto_diff/pull/150)
- Minimum Ecto version required is now 3.8 to be able to inspect virtual fields.

## [0.4.0][]

### Added

- Added `EctoDiff.diff/3` to allow options to be specified when performing a diff.
- Added `:overrides` as an option for diffing. This option allows specification of an alternate primary key for a specific struct in a diff. Unspecified structs will use their default primary key.

### Updated

- Dependencies:

  - credo 1.6.3 => 1.6.4
  - db_connection 2.4.1 => 2.4.2
  - dialyzer 1.0.0-rc.5 => 1.1.0
  - earmark_parser 1.4.19 => 1.4.25
  - ecto 3.7.1 => 3.7.2
  - ex_doc 0.28.0 => 0.28.3
  - makeup 1.0.5 => 1.1.0
  - makeup_elixir 0.15.2 => 0.16.0 (minor)
  - nimble_parsec 1.2.1 => 1.2.3
  - postgrex 0.16.1 => 0.16.2

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

[Unreleased]: https://github.com/peek-travel/ecto_diff/compare/0.5.0...HEAD
[0.5.1]: https://github.com/peek-travel/ecto_diff/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/peek-travel/ecto_diff/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/peek-travel/ecto_diff/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/peek-travel/ecto_diff/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/peek-travel/ecto_diff/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/peek-travel/ecto_diff/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/peek-travel/ecto_diff/compare/0.1.0...0.2.0
