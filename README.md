# fluent-plugin-input-jsonstream

[![Build Status](https://travis-ci.org/MerlinDMC/fluent-plugin-input-jsonstream.svg?branch=master)](https://travis-ci.org/MerlinDMC/fluent-plugin-input-jsonstream)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-input-jsonstream.svg)](http://badge.fury.io/rb/fluent-plugin-input-jsonstream)

## Overview

A streaming JSON input for [Fluentd](http://www.fluentd.org/).

### Configuration

Accept chunked JSON objects via TCP

```
<source>
  @type jsonstream
  tag example.jsonstream
  bind 127.0.0.1
  port 12345
</source>

<match example.jsonstream>
  type stdout
</match>
```
