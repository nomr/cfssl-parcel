# pki-parcel
pki-parcel is a CDH5.x parcel for CloudFlare's PKI Toolkit.

[![Build Status](https://travis-ci.org/nomr/pki-parcel.svg?branch=master)](https://travis-ci.org/nomr/pki-parcel)

## Requirements 
  - jq
  - go 1.8+
  - Java 7 or higher
  - Maven 3
  - Python 2.7/3.3 or higher

## Build Instructions
  1. Run `make`

## Release Instructions
  1. Tag the branch according to the format `v[cfssl version]+[parcel version]`.
  2. Push it to github.
  3. Wait for Travis to build it.
